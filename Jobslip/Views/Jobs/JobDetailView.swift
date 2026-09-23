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
                    Text(job.client?.name ?? "No client")
                        .font(.title2.weight(.bold))
                    Text(job.serviceName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    HStack {
                        StatusBadge(status: job.status)
                        Spacer()
                        Text(job.amount.formatted(currencyCode: currencyCode))
                            .font(.title3.weight(.bold))
                    }
                    Label(job.scheduledAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let invoiceNumber = job.invoiceNumber {
                        Text(String(format: "Invoice INV-%04d", invoiceNumber))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let estimateNumber = job.estimateNumber {
                        Text(String(format: "Estimate EST-%04d", estimateNumber))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            if !job.notes.isEmpty {
                Section("Notes") {
                    Text(job.notes)
                }
            }

            Section("Photos") {
                photoGrid(title: "Before", kind: .before, photos: job.beforePhotos)
                photoGrid(title: "After", kind: .after, photos: job.afterPhotos)
            }

            Section("Actions") {
                if job.status == .estimate {
                    Button("Convert estimate to job") {
                        job.status = .scheduled
                        try? modelContext.save()
                        WidgetSnapshotWriter.refresh()
                    }
                    Button("Share estimate PDF") {
                        generatePDF(kind: .estimate)
                    }
                }

                if job.status == .scheduled {
                    Button("Start job") {
                        job.status = .inProgress
                        try? modelContext.save()
                        WidgetSnapshotWriter.refresh()
                    }
                }

                if job.status == .inProgress {
                    Button("Mark done") {
                        job.status = .done
                        job.completedAt = Date()
                        try? modelContext.save()
                        WidgetSnapshotWriter.refresh()
                    }
                }

                if job.status == .estimate {
                    EmptyView()
                } else if job.status == .paid {
                    Button("Share paid invoice") {
                        generatePDF(kind: .invoice)
                    }
                } else if job.status == .invoiced {
                    Button("Share invoice PDF") {
                        generatePDF(kind: .invoice)
                    }
                    Button("Mark paid") {
                        job.status = .paid
                        job.completedAt = Date()
                        try? modelContext.save()
                        WidgetSnapshotWriter.refresh()
                    }
                    .foregroundStyle(FieldFolioTheme.success)
                } else {
                    // scheduled, inProgress, done
                    Button("Create invoice PDF") {
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
        .navigationTitle("Job")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEditor = true }
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
        .confirmationDialog("Add photo", isPresented: Binding(
            get: { photoSourceKind != nil },
            set: { if !$0 { photoSourceKind = nil } }
        ), titleVisibility: .visible) {
            Button("Camera") {
                if let kind = photoSourceKind { showingCameraKind = kind }
                photoSourceKind = nil
            }
            Button("Photo Library") {
                if let kind = photoSourceKind { showingLibraryKind = kind }
                photoSourceKind = nil
            }
            Button("Cancel", role: .cancel) { photoSourceKind = nil }
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
                Text("No \(title.lowercased()) photos")
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
                                            Label("Delete", systemImage: "trash")
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
                clientName: job.client?.name ?? "Client",
                clientAddress: job.client?.address ?? "",
                serviceName: job.serviceName,
                amount: job.amount,
                currencyCode: currencyCode,
                notes: job.notes,
                number: number,
                date: Date(),
                beforeImages: before,
                afterImages: after,
                watermark: entitlements.shouldWatermarkPDFs,
                isPaid: job.status == .paid
            )
        )

        guard !data.isEmpty else {
            exportError = "Could not build the PDF. Try again."
            return
        }

        let prefix = kind == .estimate ? "Estimate" : "Invoice"
        let suggested = String(format: "%@-%04d-%@", prefix, number, job.client?.name ?? "Job")

        do {
            let document = try ExportablePDF.make(data: data, suggestedName: suggested)
            try? modelContext.save()
            WidgetSnapshotWriter.refresh()
            exportDocument = document
        } catch {
            exportError = "Could not save the PDF: \(error.localizedDescription)"
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
