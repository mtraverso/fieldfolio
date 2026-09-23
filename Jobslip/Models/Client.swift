import Foundation
import SwiftData

@Model
final class Client {
    var id: UUID
    var name: String
    var phone: String
    var address: String
    var defaultRate: Decimal
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Job.client)
    var jobs: [Job]

    init(
        name: String,
        phone: String = "",
        address: String = "",
        defaultRate: Decimal = 0,
        notes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.phone = phone
        self.address = address
        self.defaultRate = defaultRate
        self.notes = notes
        self.createdAt = Date()
        self.jobs = []
    }
}
