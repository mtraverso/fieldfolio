import Foundation
import SwiftData

@Model
final class JobLineItem {
    var id: UUID
    var title: String
    var quantity: Decimal
    var unitPrice: Decimal
    var sortIndex: Int
    var job: Job?

    init(
        title: String,
        quantity: Decimal = 1,
        unitPrice: Decimal = 0,
        sortIndex: Int = 0,
        job: Job? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.sortIndex = sortIndex
        self.job = job
    }

    var lineTotal: Decimal {
        quantity * unitPrice
    }
}
