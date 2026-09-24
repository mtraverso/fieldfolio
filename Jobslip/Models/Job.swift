import Foundation
import SwiftData

@Model
final class Job {
    var id: UUID
    var serviceName: String
    var amount: Decimal
    var notes: String
    var statusRaw: String
    var scheduledAt: Date
    var createdAt: Date
    var completedAt: Date?
    var invoiceNumber: Int?
    var estimateNumber: Int?
    var taxPercent: Decimal = 0
    var discountAmount: Decimal = 0
    var isSample: Bool = false
    var client: Client?

    @Relationship(deleteRule: .cascade, inverse: \JobPhoto.job)
    var photos: [JobPhoto]

    @Relationship(deleteRule: .cascade, inverse: \JobLineItem.job)
    var lineItems: [JobLineItem]

    var status: JobStatus {
        get { JobStatus(rawValue: statusRaw) ?? .scheduled }
        set { statusRaw = newValue.rawValue }
    }

    init(
        serviceName: String,
        amount: Decimal,
        notes: String = "",
        status: JobStatus = .scheduled,
        scheduledAt: Date = Date(),
        client: Client? = nil,
        taxPercent: Decimal = 0,
        discountAmount: Decimal = 0,
        isSample: Bool = false
    ) {
        self.id = UUID()
        self.serviceName = serviceName
        self.amount = amount
        self.notes = notes
        self.statusRaw = status.rawValue
        self.scheduledAt = scheduledAt
        self.createdAt = Date()
        self.completedAt = nil
        self.invoiceNumber = nil
        self.estimateNumber = nil
        self.taxPercent = taxPercent
        self.discountAmount = discountAmount
        self.isSample = isSample
        self.client = client
        self.photos = []
        self.lineItems = []
    }

    var sortedLineItems: [JobLineItem] {
        lineItems.sorted { $0.sortIndex < $1.sortIndex }
    }

    /// Effective lines for display/PDF: stored items, or a synthetic line from legacy cache.
    var effectiveLineItems: [(title: String, quantity: Decimal, unitPrice: Decimal)] {
        let sorted = sortedLineItems
        if sorted.isEmpty {
            if serviceName.isEmpty && amount == 0 { return [] }
            return [(title: serviceName, quantity: 1, unitPrice: amount)]
        }
        return sorted.map { (title: $0.title, quantity: $0.quantity, unitPrice: $0.unitPrice) }
    }

    var subtotal: Decimal {
        effectiveLineItems.reduce(Decimal(0)) { $0 + ($1.quantity * $1.unitPrice) }
    }

    var taxAmount: Decimal {
        let taxable = max(subtotal - discountAmount, 0)
        return taxable * taxPercent / 100
    }

    var total: Decimal {
        max(subtotal - discountAmount, 0) + taxAmount
    }

    func recalculateTotals() {
        let sorted = sortedLineItems
        if sorted.isEmpty {
            // Keep existing serviceName/amount if no line items yet.
            return
        }
        if sorted.count == 1 {
            serviceName = sorted[0].title
        } else {
            serviceName = sorted.map(\.title).joined(separator: ", ")
        }
        amount = total
    }

    var beforePhotos: [JobPhoto] {
        photos.filter { $0.kind == .before }.sorted { $0.createdAt < $1.createdAt }
    }

    var afterPhotos: [JobPhoto] {
        photos.filter { $0.kind == .after }.sorted { $0.createdAt < $1.createdAt }
    }
}
