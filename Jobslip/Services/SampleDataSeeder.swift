import Foundation
import SwiftData
import UIKit

enum SampleDataSeeder {
    static func seedIfNeeded(context: ModelContext) {
        let profileDescriptor = FetchDescriptor<BusinessProfile>()
        let existingProfiles = (try? context.fetch(profileDescriptor)) ?? []
        if existingProfiles.isEmpty {
            context.insert(BusinessProfile())
        }

        let clientDescriptor = FetchDescriptor<Client>()
        let existingClients = (try? context.fetch(clientDescriptor)) ?? []
        guard existingClients.isEmpty else { return }

        let garcia = Client(
            name: "Carlos Garcia",
            phone: "555-0142",
            address: "128 Maple St",
            defaultRate: 180,
            notes: "Honda Accord — interior detail regular"
        )
        let nguyen = Client(
            name: "Linh Nguyen",
            phone: "555-0198",
            address: "44 Oak Ave",
            defaultRate: 120,
            notes: "Weekly house clean"
        )
        let park = Client(
            name: "James Park",
            phone: "555-0177",
            address: "9 Harbor Rd",
            defaultRate: 250,
            notes: "Full detail + ceramic"
        )

        context.insert(garcia)
        context.insert(nguyen)
        context.insert(park)

        let today = Calendar.current.startOfDay(for: Date())
        let morning = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today
        let afternoon = Calendar.current.date(bySettingHour: 13, minute: 30, second: 0, of: today) ?? today
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: morning) ?? morning
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: morning) ?? morning

        let job1 = Job(
            serviceName: "Sedan interior detail",
            amount: 180,
            notes: "Pet hair on back seats",
            status: .scheduled,
            scheduledAt: morning,
            client: garcia
        )
        let job2 = Job(
            serviceName: "Standard house clean",
            amount: 120,
            notes: "Focus on kitchen",
            status: .scheduled,
            scheduledAt: afternoon,
            client: nguyen
        )
        let job3 = Job(
            serviceName: "Full exterior wash",
            amount: 95,
            notes: "Estimate sent Monday",
            status: .estimate,
            scheduledAt: tomorrow,
            client: park
        )
        job3.estimateNumber = 1

        let job4 = Job(
            serviceName: "Move-out clean",
            amount: 220,
            notes: "Awaiting payment",
            status: .invoiced,
            scheduledAt: yesterday,
            client: nguyen
        )
        job4.invoiceNumber = 11
        job4.completedAt = yesterday

        let paidDay = Calendar.current.date(byAdding: .day, value: -1, to: morning) ?? morning
        let job5 = Job(
            serviceName: "SUV full detail",
            amount: 250,
            notes: "Paid via Venmo",
            status: .paid,
            scheduledAt: paidDay,
            client: park
        )
        job5.invoiceNumber = 10
        job5.completedAt = paidDay

        for job in [job1, job2, job3, job4, job5] {
            context.insert(job)
        }

        if let placeholder = placeholderImageData() {
            let before = JobPhoto(kind: .before, imageData: placeholder, job: job4)
            let after = JobPhoto(kind: .after, imageData: placeholder, job: job4)
            context.insert(before)
            context.insert(after)
        }

        let profile = (try? context.fetch(profileDescriptor))?.first
        profile?.businessName = "Maria's Mobile Detail"
        profile?.phone = "555-0100"
        profile?.email = "maria@example.com"
        profile?.nextInvoiceNumber = 12
        profile?.nextEstimateNumber = 2
        // Leave hasCompletedOnboarding false so first launch shows onboarding with fields prefilled.

        try? context.save()
    }

    private static func placeholderImageData() -> Data? {
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor(red: 0.85, green: 0.88, blue: 0.92, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
                .foregroundColor: UIColor.darkGray
            ]
            let text = "Sample photo"
            let textSize = text.size(withAttributes: attrs)
            let origin = CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            )
            text.draw(at: origin, withAttributes: attrs)
        }
        return image.jpegData(compressionQuality: 0.8)
    }
}
