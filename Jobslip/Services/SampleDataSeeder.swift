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
            notes: "Honda Accord — interior detail regular",
            isSample: true
        )
        let nguyen = Client(
            name: "Linh Nguyen",
            phone: "555-0198",
            address: "44 Oak Ave",
            defaultRate: 120,
            notes: "Weekly house clean",
            isSample: true
        )
        let park = Client(
            name: "James Park",
            phone: "555-0177",
            address: "9 Harbor Rd",
            defaultRate: 250,
            notes: "Full detail + ceramic",
            isSample: true
        )

        context.insert(garcia)
        context.insert(nguyen)
        context.insert(park)

        let today = Calendar.current.startOfDay(for: Date())
        let morning = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today
        let afternoon = Calendar.current.date(bySettingHour: 13, minute: 30, second: 0, of: today) ?? today
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: morning) ?? morning
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: morning) ?? morning

        let job1 = makeJob(
            context: context,
            serviceLines: [("Sedan interior detail", 1, 180)],
            notes: "Pet hair on back seats",
            status: .scheduled,
            scheduledAt: morning,
            client: garcia
        )
        let job2 = makeJob(
            context: context,
            serviceLines: [("Standard house clean", 1, 120)],
            notes: "Focus on kitchen",
            status: .scheduled,
            scheduledAt: afternoon,
            client: nguyen,
            taxPercent: 8.25
        )
        let job3 = makeJob(
            context: context,
            serviceLines: [("Full exterior wash", 1, 95)],
            notes: "Estimate sent Monday",
            status: .estimate,
            scheduledAt: tomorrow,
            client: park,
            discountAmount: 10
        )
        job3.estimateNumber = 1

        let job4 = makeJob(
            context: context,
            serviceLines: [
                ("Move-out clean — labor", 1, 180),
                ("Cleaning supplies", 1, 40)
            ],
            notes: "Awaiting payment",
            status: .invoiced,
            scheduledAt: yesterday,
            client: nguyen,
            taxPercent: 8.25
        )
        job4.invoiceNumber = 11
        job4.completedAt = yesterday

        let paidDay = Calendar.current.date(byAdding: .day, value: -1, to: morning) ?? morning
        let job5 = makeJob(
            context: context,
            serviceLines: [
                ("SUV full detail", 1, 220),
                ("Ceramic spray", 1, 45)
            ],
            notes: "Paid via Venmo",
            status: .paid,
            scheduledAt: paidDay,
            client: park,
            discountAmount: 15
        )
        job5.invoiceNumber = 10
        job5.completedAt = paidDay

        _ = [job1, job2, job3, job4, job5]

        if let before = bundledPhoto(named: "sample-before-room") ?? bundledPhoto(named: "sample-before"),
           let after = bundledPhoto(named: "sample-after-room") ?? bundledPhoto(named: "sample-after") {
            context.insert(JobPhoto(kind: .before, imageData: before, job: job4))
            context.insert(JobPhoto(kind: .after, imageData: after, job: job4))
        } else if let placeholder = placeholderImageData(label: "Before") {
            context.insert(JobPhoto(kind: .before, imageData: placeholder, job: job4))
            if let afterPlaceholder = placeholderImageData(label: "After") {
                context.insert(JobPhoto(kind: .after, imageData: afterPlaceholder, job: job4))
            }
        }

        // Leave business profile blank so onboarding is for the user's real business.
        let profile = (try? context.fetch(profileDescriptor))?.first
        profile?.nextInvoiceNumber = 12
        profile?.nextEstimateNumber = 2

        try? context.save()
    }

    static func hasSampleData(clients: [Client], jobs: [Job]) -> Bool {
        clients.contains(where: \.isSample) || jobs.contains(where: \.isSample)
    }

    static func removeSampleData(context: ModelContext, clients: [Client], jobs: [Job]) {
        for job in jobs where job.isSample {
            NotificationService.cancelJobReminder(jobID: job.id)
            context.delete(job)
        }
        for client in clients where client.isSample {
            context.delete(client)
        }

        let remainingJobs = (try? context.fetch(FetchDescriptor<Job>())) ?? []
        if let profile = (try? context.fetch(FetchDescriptor<BusinessProfile>()))?.first {
            let maxInvoice = remainingJobs.compactMap(\.invoiceNumber).max() ?? 0
            let maxEstimate = remainingJobs.compactMap(\.estimateNumber).max() ?? 0
            profile.nextInvoiceNumber = max(maxInvoice + 1, 1)
            profile.nextEstimateNumber = max(maxEstimate + 1, 1)
        }

        try? context.save()
        WidgetSnapshotWriter.refresh()
    }

    @discardableResult
    private static func makeJob(
        context: ModelContext,
        serviceLines: [(String, Decimal, Decimal)],
        notes: String,
        status: JobStatus,
        scheduledAt: Date,
        client: Client,
        taxPercent: Decimal = 0,
        discountAmount: Decimal = 0
    ) -> Job {
        let firstTitle = serviceLines.first?.0 ?? "Job"
        let job = Job(
            serviceName: firstTitle,
            amount: 0,
            notes: notes,
            status: status,
            scheduledAt: scheduledAt,
            client: client,
            taxPercent: taxPercent,
            discountAmount: discountAmount,
            isSample: true
        )
        context.insert(job)
        for (index, line) in serviceLines.enumerated() {
            let item = JobLineItem(
                title: line.0,
                quantity: line.1,
                unitPrice: line.2,
                sortIndex: index,
                job: job
            )
            context.insert(item)
            job.lineItems.append(item)
        }
        job.recalculateTotals()
        return job
    }

    private static func bundledPhoto(named name: String) -> Data? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "jpg")
                ?? Bundle.main.url(forResource: name, withExtension: "png")
        else { return nil }
        return try? Data(contentsOf: url)
    }

    private static func placeholderImageData(label: String) -> Data? {
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let color = label == "Before"
                ? UIColor(red: 0.75, green: 0.72, blue: 0.68, alpha: 1)
                : UIColor(red: 0.72, green: 0.85, blue: 0.90, alpha: 1)
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
                .foregroundColor: UIColor.darkGray
            ]
            let textSize = label.size(withAttributes: attrs)
            let origin = CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            )
            label.draw(at: origin, withAttributes: attrs)
        }
        return image.jpegData(compressionQuality: 0.8)
    }
}
