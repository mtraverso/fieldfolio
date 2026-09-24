import SwiftUI
import SwiftData
import UIKit

struct JobDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BusinessProfile]
    @EnvironmentObject private var entitlements: EntitlementStore

    @Bindable var job: Job

    @State private var showingEditor = false
    @State private var showingCameraKind: PhotoKind?
    @State private var showingLibraryKind: PhotoKind?
    @State private var exportDocument: ExportablePDF?
    @State private var showingPaywall = false
    @State private var photoSourceKind: PhotoKind?
    @State private var exportError: String?

    private var profile: BusinessProfile {
        if let existing = profiles.first {
            return existing
        }
        let created = BusinessProfile()
        modelContext.insert(created)
        return created
    }

    private var currencyCode: String { profile.currencyCode }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(job.client?.name ?? String(localized: "No client"))
                        .font(.title2.weight(.bold))
                    Text(job.serviceName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    HStack {
                        StatusBadge(status: job.status)
                        Spacer()
                        Text(job.total.formatted(currencyCode: currencyCode))
                            .font(.title3.weight(.bold))
                    }
                    Label(job.scheduledAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let invoiceNumber = job.invoiceNumber {
                        Text(String(format: String(localized: "Invoice INV-%04d"), invoiceNumber))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let estimateNumber = job.estimateNumber {
                        Text(String(format: String(localized: "Estimate EST-%04d"), estimateNumber))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            let lines = job.effectiveLineItems
            if lines.count > 1 || job.taxPercent > 0 || job.discountAmount > 0 {
                Section(String(localized: "Line items")) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(line.title)
                                if line.quantity != 1 {
                                    Text("\(line.quantity) × \(line.unitPrice.formatted(currencyCode: currencyCode))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text((line.quantity * line.unitPrice).formatted(currencyCode: currencyCode))
                        }
                    }
                    if job.discountAmount > 0 || job.taxPercent > 0 {
                        LabeledContent(String(localized: "Subtotal"), value: job.subtotal.formatted(currencyCode: currencyCode))
                    }
                    if job.discountAmount > 0 {
                        LabeledContent(String(localized: "Discount"), value: "−\(job.discountAmount.formatted(currencyCode: currencyCode))")
                    }
                    if job.taxPercent > 0 {
                        LabeledContent(
                            String(format: String(localized: "Tax (%@%%)"), "\(job.taxPercent)"),
                            value: job.taxAmount.formatted(currencyCode: currencyCode)
                        )
                    }
                    LabeledContent(String(localized: "Total"), value: job.total.formatted(currencyCode: currencyCode))
                        .font(.body.weight(.semibold))
                }
            }

            if !job.notes.isEmpty {
                Section(String(localized: "Notes")) {
                    Text(job.notes)
                }
            }

            Section(String(localized: "Photos")) {
                photoGrid(title: String(localized: "Before"), kind: .before, photos: job.beforePhotos)
                photoGrid(title: String(localized: "After"), kind: .after, photos: job.afterPhotos)
            }

            Section(String(localized: "Actions")) {
                if job.status == .estimate {
                    Button(String(localized: "Convert estimate to job")) {
                        job.status = .scheduled
                        try? modelContext.save()
                        WidgetSnapshotWriter.refresh()
                    }
                    Button(String(localized: "Share estimate PDF")) {
                        generatePDF(kind: .estimate)
                    }
                }

                if job.status == .scheduled {
                    Button(String(localized: "Start job")) {
                        job.status = .inProgress
                        try? modelContext.save()
                        WidgetSnapshotWriter.refresh()
                    }
                }

                if job.status == .inProgress {
                    Button(String(localized: "Mark done")) {
                        job.status = .done
                        job.completedAt = Date()
                        try? modelContext.save()
                        WidgetSnapshotWriter.refresh()
                    }
                }

                if job.status == .estimate {
                    EmptyView()
                } else if job.status == .paid {
                    Button(String(localized: "Share paid invoice")) {
                        generatePDF(kind: .invoice)
                    }
                } else if job.status == .invoiced {
                    Button(String(localized: "Share invoice PDF")) {
                        generatePDF(kind: .invoice)
                    }
                    Button(String(localized: "Mark paid")) {
                        job.status = .paid
                        job.completedAt = Date()
                        try? modelContext.save()
                        WidgetSnapshotWriter.refresh()
                    }
                    .foregroundStyle(FieldFolioTheme.success)
                } else {
                    Button(String(localized: "Create invoice PDF")) {
                        generatePDF(kind: .invoice)
                    }
                }
            }

            if let exportError {
                Section {
                    Text(exportError)
                        .foregroundStyle(FieldFolioTheme.danger)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle(String(localized: "Job"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "Edit")) { showingEditor = true }
            }
        }
        .sheet(isPresented: $showingEditor) {
            JobEditorView(job: job)
        }
        .sheet(item: $showingCameraKind) { kind in
            ImagePicker(source: .camera) { image in
                addPhoto(image, kind: kind)
            }
            .ignoresSafeArea()
        }
        .sheet(item: $showingLibraryKind) { kind in
            ImagePicker(source: .library) { image in
                addPhoto(image, kind: kind)
            }
            .ignoresSafeArea()
        }
        .confirmationDialog(String(localized: "Add photo"), isPresented: Binding(
            get: { photoSourceKind != nil },
            set: { if !$0 { photoSourceKind = nil } }
        ), titleVisibility: .visible) {
            Button(String(localized: "Camera")) {
                if let kind = photoSourceKind { showingCameraKind = kind }
                photoSourceKind = nil
            }
            Button(String(localized: "Photo Library")) {
                if let kind = photoSourceKind { showingLibraryKind = kind }
                photoSourceKind = nil
            }
            Button(String(localized: "Cancel"), role: .cancel) { photoSourceKind = nil }
        }
        .sheet(item: $exportDocument) { document in
            PDFPreviewView(document: document)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    @ViewBuilder
    private func photoGrid(title: String, kind: PhotoKind, photos: [JobPhoto]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    photoSourceKind = kind
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            if photos.isEmpty {
                Text(kind == .before
                      ? String(localized: "No before photos")
                      : String(localized: "No after photos"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(photos) { photo in
                            if let uiImage = UIImage(data: photo.imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 96, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            modelContext.delete(photo)
                                            try? modelContext.save()
                                        } label: {
                                            Label(String(localized: "Delete"), systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
            }
        }
    }

    private func addPhoto(_ image: UIImage, kind: PhotoKind) {
        let resized = image.resized(maxDimension: 1600)
        guard let data = resized.jpegData(compressionQuality: 0.75) else { return }
        let photo = JobPhoto(kind: kind, imageData: data, job: job)
        modelContext.insert(photo)
        try? modelContext.save()
    }

    private func generatePDF(kind: PDFDocumentKind) {
        exportError = nil
        let profile = self.profile

        let number: Int
        if kind == .estimate {
            if let existing = job.estimateNumber {
                number = existing
            } else {
                number = max(profile.nextEstimateNumber, 1)
                job.estimateNumber = number
                profile.nextEstimateNumber = number + 1
            }
        } else {
            if let existing = job.invoiceNumber {
                number = existing
            } else {
                number = max(profile.nextInvoiceNumber, 1)
                job.invoiceNumber = number
                profile.nextInvoiceNumber = number + 1
            }
            if job.status != .paid {
                job.status = .invoiced
                if job.completedAt == nil {
                    job.completedAt = Date()
                }
            }
        }

        let before = job.beforePhotos.compactMap { UIImage(data: $0.imageData) }
        let after = job.afterPhotos.compactMap { UIImage(data: $0.imageData) }

        let data = PDFGenerator.make(
            input: .init(
                kind: kind,
                businessName: profile.businessName,
                businessPhone: profile.phone,
                businessEmail: profile.email,
                clientName: job.client?.name ?? String(localized: "Client"),
                clientAddress: job.client?.address ?? "",
                lineItems: job.effectiveLineItems.map {
                    PDFGenerator.LineItem(title: $0.title, quantity: $0.quantity, unitPrice: $0.unitPrice)
                },
                taxPercent: job.taxPercent,
                discountAmount: job.discountAmount,
                currencyCode: currencyCode,
                notes: job.notes,
                number: number,
                date: Date(),
                beforeImages: before,
                afterImages: after,
                watermark: entitlements.shouldWatermarkPDFs,
                isPaid: job.status == .paid,
                paymentInstructions: profile.paymentInstructions
            )
        )

        guard !data.isEmpty else {
            exportError = String(localized: "Could not build the PDF. Try again.")
            return
        }

        let prefix = kind == .estimate ? String(localized: "Estimate") : String(localized: "Invoice")
        let suggested = String(format: "%@-%04d-%@", prefix, number, job.client?.name ?? "Job")

        do {
            let document = try ExportablePDF.make(data: data, suggestedName: suggested)
            try? modelContext.save()
            WidgetSnapshotWriter.refresh()
            exportDocument = document
        } catch {
            exportError = String(localized: "Could not save the PDF: \(error.localizedDescription)")
        }
    }
}

extension PhotoKind: Identifiable {
    var id: String { rawValue }
}

extension JobPhoto: Identifiable {}

private extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
