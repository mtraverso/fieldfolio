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
    var client: Client?

    @Relationship(deleteRule: .cascade, inverse: \JobPhoto.job)
    var photos: [JobPhoto]

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
        client: Client? = nil
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
        self.client = client
        self.photos = []
    }

    var beforePhotos: [JobPhoto] {
        photos.filter { $0.kind == .before }.sorted { $0.createdAt < $1.createdAt }
    }

    var afterPhotos: [JobPhoto] {
        photos.filter { $0.kind == .after }.sorted { $0.createdAt < $1.createdAt }
    }
}
