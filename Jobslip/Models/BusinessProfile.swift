import Foundation
import SwiftData

@Model
final class BusinessProfile {
    var id: UUID
    var businessName: String
    var phone: String
    var email: String
    var currencyCode: String
    var paymentInstructions: String = ""
    var nextInvoiceNumber: Int
    var nextEstimateNumber: Int
    var hasCompletedOnboarding: Bool
    var faceIDEnabled: Bool

    init(
        businessName: String = "",
        phone: String = "",
        email: String = "",
        currencyCode: String = "USD",
        paymentInstructions: String = ""
    ) {
        self.id = UUID()
        self.businessName = businessName
        self.phone = phone
        self.email = email
        self.currencyCode = currencyCode
        self.paymentInstructions = paymentInstructions
        self.nextInvoiceNumber = 1
        self.nextEstimateNumber = 1
        self.hasCompletedOnboarding = false
        self.faceIDEnabled = false
    }
}
