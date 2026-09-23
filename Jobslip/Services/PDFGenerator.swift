import Foundation
import PDFKit
import UIKit

enum PDFDocumentKind {
    case estimate
    case invoice
}

struct PDFGenerator {
    struct Input {
        let kind: PDFDocumentKind
        let businessName: String
        let businessPhone: String
        let businessEmail: String
        let clientName: String
        let clientAddress: String
        let serviceName: String
        let amount: Decimal
        let currencyCode: String
        let notes: String
        let number: Int
        let date: Date
        let beforeImages: [UIImage]
        let afterImages: [UIImage]
        let watermark: Bool
        let isPaid: Bool
    }

    static func make(input: Input) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
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
            let title = input.kind == .estimate ? "ESTIMATE" : "INVOICE"
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
            drawText(
                "Date: \(dateFormatter.string(from: input.date))",
                at: CGPoint(x: left, y: y),
                font: .systemFont(ofSize: 12),
                color: .darkGray
            )
            y += 24

            drawText("Bill to", at: CGPoint(x: left, y: y), font: .boldSystemFont(ofSize: 12), color: .black)
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
            drawText("Service", at: CGPoint(x: left + 8, y: y + 7), font: .boldSystemFont(ofSize: 12), color: .black)
            let amountHeader = "Amount"
            let amountHeaderSize = amountHeader.size(withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12)])
            drawText(amountHeader, at: CGPoint(x: right - amountHeaderSize.width - 8, y: y + 7), font: .boldSystemFont(ofSize: 12), color: .black)
            y += 36

            drawText(input.serviceName, at: CGPoint(x: left + 8, y: y), font: .systemFont(ofSize: 13), color: .black)
            let amountText = input.amount.formatted(currencyCode: input.currencyCode)
            let amountSize = amountText.size(withAttributes: [.font: UIFont.systemFont(ofSize: 13)])
            drawText(amountText, at: CGPoint(x: right - amountSize.width - 8, y: y), font: .systemFont(ofSize: 13), color: .black)
            y += 28

            if !input.notes.isEmpty {
                drawText("Notes", at: CGPoint(x: left, y: y), font: .boldSystemFont(ofSize: 12), color: .black)
                y += 16
                y = drawWrappedText(input.notes, in: CGRect(x: left, y: y, width: width, height: 80), font: .systemFont(ofSize: 12), color: .darkGray)
                y += 12
            }

            // Total
            y += 8
            UIColor(white: 0.95, alpha: 1).setFill()
            UIBezierPath(rect: CGRect(x: left, y: y, width: width, height: 36)).fill()
            drawText("Total", at: CGPoint(x: left + 8, y: y + 10), font: .boldSystemFont(ofSize: 14), color: .black)
            let totalSize = amountText.size(withAttributes: [.font: UIFont.boldSystemFont(ofSize: 14)])
            drawText(amountText, at: CGPoint(x: right - totalSize.width - 8, y: y + 10), font: .boldSystemFont(ofSize: 14), color: .black)
            y += 48

            if input.kind == .invoice && input.isPaid {
                drawText("PAID", at: CGPoint(x: left, y: y), font: .boldSystemFont(ofSize: 18), color: UIColor(red: 0.15, green: 0.62, blue: 0.38, alpha: 1))
                y += 28
            }

            // Photos
            let photos = Array((input.beforeImages + input.afterImages).prefix(4))
            if !photos.isEmpty {
                drawText("Photos", at: CGPoint(x: left, y: y), font: .boldSystemFont(ofSize: 12), color: .black)
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
            }

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
