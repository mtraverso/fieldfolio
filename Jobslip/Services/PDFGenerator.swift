import Foundation
import PDFKit
import UIKit

enum PDFDocumentKind {
    case estimate
    case invoice
}

struct PDFGenerator {
    struct LineItem {
        let title: String
        let quantity: Decimal
        let unitPrice: Decimal

        var lineTotal: Decimal { quantity * unitPrice }
    }

    struct Input {
        let kind: PDFDocumentKind
        let businessName: String
        let businessPhone: String
        let businessEmail: String
        let clientName: String
        let clientAddress: String
        let lineItems: [LineItem]
        let taxPercent: Decimal
        let discountAmount: Decimal
        let currencyCode: String
        let notes: String
        let number: Int
        let date: Date
        let beforeImages: [UIImage]
        let afterImages: [UIImage]
        let watermark: Bool
        let isPaid: Bool
        let paymentInstructions: String
    }

    static func make(input: Input) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let locale = Locale.current

        let estimateTitle = String(localized: "ESTIMATE", locale: locale)
        let invoiceTitle = String(localized: "INVOICE", locale: locale)
        let billTo = String(localized: "Bill to", locale: locale)
        let serviceHeader = String(localized: "Service", locale: locale)
        let qtyHeader = String(localized: "Qty", locale: locale)
        let amountHeader = String(localized: "Amount", locale: locale)
        let notesHeader = String(localized: "Notes", locale: locale)
        let subtotalLabel = String(localized: "Subtotal", locale: locale)
        let discountLabel = String(localized: "Discount", locale: locale)
        let totalLabel = String(localized: "Total", locale: locale)
        let paidLabel = String(localized: "PAID", locale: locale)
        let howToPay = String(localized: "How to pay", locale: locale)
        let photosHeader = String(localized: "Photos", locale: locale)
        let datePrefix = String(localized: "Date:", locale: locale)

        return renderer.pdfData { context in
            context.beginPage()
            let cg = context.cgContext

            var y: CGFloat = 40
            let left: CGFloat = 40
            let right: CGFloat = pageRect.width - 40
            let width = right - left

            drawText(
                input.businessName.isEmpty ? "FieldFolio" : input.businessName,
                at: CGPoint(x: left, y: y),
                font: .boldSystemFont(ofSize: 22),
                color: .black
            )
            y += 28

            let contact = [input.businessPhone, input.businessEmail]
                .filter { !$0.isEmpty }
                .joined(separator: "  ·  ")
            if !contact.isEmpty {
                drawText(contact, at: CGPoint(x: left, y: y), font: .systemFont(ofSize: 11), color: .darkGray)
                y += 18
            }

            y += 8
            let title = input.kind == .estimate ? estimateTitle : invoiceTitle
            drawText(title, at: CGPoint(x: left, y: y), font: .boldSystemFont(ofSize: 16), color: UIColor(red: 0.12, green: 0.45, blue: 0.72, alpha: 1))

            let numberLabel = input.kind == .estimate
                ? String(format: "EST-%04d", input.number)
                : String(format: "INV-%04d", input.number)
            let numberSize = numberLabel.size(withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
            drawText(
                numberLabel,
                at: CGPoint(x: right - numberSize.width, y: y + 2),
                font: .systemFont(ofSize: 12),
                color: .darkGray
            )
            y += 28

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.locale = locale
            drawText(
                "\(datePrefix) \(dateFormatter.string(from: input.date))",
                at: CGPoint(x: left, y: y),
                font: .systemFont(ofSize: 12),
                color: .darkGray
            )
            y += 24

            drawText(billTo, at: CGPoint(x: left, y: y), font: .boldSystemFont(ofSize: 12), color: .black)
            y += 16
            drawText(input.clientName, at: CGPoint(x: left, y: y), font: .systemFont(ofSize: 13), color: .black)
            y += 16
            if !input.clientAddress.isEmpty {
                drawText(input.clientAddress, at: CGPoint(x: left, y: y), font: .systemFont(ofSize: 12), color: .darkGray)
                y += 16
            }
            y += 16

            // Line item header
            UIColor(white: 0.93, alpha: 1).setFill()
            UIBezierPath(rect: CGRect(x: left, y: y, width: width, height: 28)).fill()
            drawText(serviceHeader, at: CGPoint(x: left + 8, y: y + 7), font: .boldSystemFont(ofSize: 12), color: .black)

            let qtyX = left + width * 0.55
            drawText(qtyHeader, at: CGPoint(x: qtyX, y: y + 7), font: .boldSystemFont(ofSize: 12), color: .black)

            let amountHeaderSize = amountHeader.size(withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12)])
            drawText(amountHeader, at: CGPoint(x: right - amountHeaderSize.width - 8, y: y + 7), font: .boldSystemFont(ofSize: 12), color: .black)
            y += 36

            let lines = input.lineItems.isEmpty
                ? [LineItem(title: "—", quantity: 1, unitPrice: 0)]
                : input.lineItems

            for item in lines {
                drawText(item.title, at: CGPoint(x: left + 8, y: y), font: .systemFont(ofSize: 13), color: .black)
                let qtyText = "\(item.quantity)"
                drawText(qtyText, at: CGPoint(x: qtyX, y: y), font: .systemFont(ofSize: 13), color: .darkGray)
                let lineAmount = item.lineTotal.formatted(currencyCode: input.currencyCode)
                let lineSize = lineAmount.size(withAttributes: [.font: UIFont.systemFont(ofSize: 13)])
                drawText(lineAmount, at: CGPoint(x: right - lineSize.width - 8, y: y), font: .systemFont(ofSize: 13), color: .black)
                y += 22
            }
            y += 8

            if !input.notes.isEmpty {
                drawText(notesHeader, at: CGPoint(x: left, y: y), font: .boldSystemFont(ofSize: 12), color: .black)
                y += 16
                y = drawWrappedText(input.notes, in: CGRect(x: left, y: y, width: width, height: 80), font: .systemFont(ofSize: 12), color: .darkGray)
                y += 12
            }

            let subtotal = lines.reduce(Decimal(0)) { $0 + $1.lineTotal }
            let discount = input.discountAmount
            let taxable = max(subtotal - discount, 0)
            let tax = taxable * input.taxPercent / 100
            let total = taxable + tax

            func drawSummaryRow(_ label: String, value: String, bold: Bool = false) {
                let font: UIFont = bold ? .boldSystemFont(ofSize: 14) : .systemFont(ofSize: 13)
                drawText(label, at: CGPoint(x: left + 8, y: y + 8), font: font, color: .black)
                let size = value.size(withAttributes: [.font: font])
                drawText(value, at: CGPoint(x: right - size.width - 8, y: y + 8), font: font, color: .black)
                y += bold ? 36 : 28
            }

            UIColor(white: 0.95, alpha: 1).setFill()
            let summaryHeight: CGFloat = {
                var h: CGFloat = 36
                if discount > 0 { h += 28 }
                if input.taxPercent > 0 { h += 28 }
                if discount > 0 || input.taxPercent > 0 { h += 28 } // subtotal
                return h
            }()
            UIBezierPath(rect: CGRect(x: left, y: y, width: width, height: summaryHeight)).fill()

            if discount > 0 || input.taxPercent > 0 {
                drawSummaryRow(subtotalLabel, value: subtotal.formatted(currencyCode: input.currencyCode))
                if discount > 0 {
                    drawSummaryRow(discountLabel, value: "−\(discount.formatted(currencyCode: input.currencyCode))")
                }
                if input.taxPercent > 0 {
                    let taxText = String(format: String(localized: "Tax (%@%%)", locale: locale), "\(input.taxPercent)")
                    drawSummaryRow(taxText, value: tax.formatted(currencyCode: input.currencyCode))
                }
            }
            drawSummaryRow(totalLabel, value: total.formatted(currencyCode: input.currencyCode), bold: true)
            y += 12

            if input.kind == .invoice && input.isPaid {
                drawText(paidLabel, at: CGPoint(x: left, y: y), font: .boldSystemFont(ofSize: 18), color: UIColor(red: 0.15, green: 0.62, blue: 0.38, alpha: 1))
                y += 28
            }

            if input.kind == .invoice && !input.isPaid && !input.paymentInstructions.isEmpty {
                drawText(howToPay, at: CGPoint(x: left, y: y), font: .boldSystemFont(ofSize: 12), color: .black)
                y += 16
                y = drawWrappedText(
                    input.paymentInstructions,
                    in: CGRect(x: left, y: y, width: width, height: 80),
                    font: .systemFont(ofSize: 12),
                    color: .darkGray
                )
                y += 16
            }

            let photos = Array((input.beforeImages + input.afterImages).prefix(4))
            if !photos.isEmpty {
                drawText(photosHeader, at: CGPoint(x: left, y: y), font: .boldSystemFont(ofSize: 12), color: .black)
                y += 18
                let thumbW: CGFloat = 120
                let thumbH: CGFloat = 90
                var x = left
                for image in photos {
                    let rect = CGRect(x: x, y: y, width: thumbW, height: thumbH)
                    image.draw(in: rect)
                    UIColor.lightGray.setStroke()
                    UIBezierPath(rect: rect).stroke()
                    x += thumbW + 12
                    if x + thumbW > right {
                        break
                    }
                }
                y += thumbH + 20
            }

            if input.watermark {
                cg.saveGState()
                cg.translateBy(x: pageRect.midX, y: pageRect.midY)
                cg.rotate(by: -.pi / 4)
                let watermark = "Made with FieldFolio"
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 42),
                    .foregroundColor: UIColor(white: 0.75, alpha: 0.35)
                ]
                let size = watermark.size(withAttributes: attrs)
                watermark.draw(at: CGPoint(x: -size.width / 2, y: -size.height / 2), withAttributes: attrs)
                cg.restoreGState()

                let footer = "Generated with FieldFolio"
                let footerSize = footer.size(withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
                drawText(
                    footer,
                    at: CGPoint(x: (pageRect.width - footerSize.width) / 2, y: pageRect.height - 36),
                    font: .systemFont(ofSize: 10),
                    color: .gray
                )
            }
        }
    }

    private static func drawText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        text.draw(at: point, withAttributes: attrs)
    }

    @discardableResult
    private static func drawWrappedText(_ text: String, in rect: CGRect, font: UIFont, color: UIColor) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let attributed = NSAttributedString(string: text, attributes: attrs)
        let bounding = attributed.boundingRect(with: CGSize(width: rect.width, height: rect.height), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        attributed.draw(with: CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: bounding.height), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return rect.origin.y + bounding.height
    }
}
