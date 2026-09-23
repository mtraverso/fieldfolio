import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlements: EntitlementStore
    @State private var purchasingProductID: String?

    private struct PlanCard: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let priceLabel: String
    }

    private var plans: [PlanCard] {
        let catalog: [(id: String, title: String, subtitle: String, fallback: String)] = [
            (
                EntitlementStore.monthlyID,
                "Monthly",
                "Unlimited everything. Cancel anytime.",
                "$4.99 / month"
            ),
            (
                EntitlementStore.yearlyID,
                "Yearly",
                "Best value. 7-day free trial.",
                "$29.99 / year"
            ),
            (
                EntitlementStore.lifetimeID,
                "Lifetime",
                "Pay once. Keep Pro forever.",
                "$59.99 once"
            )
        ]

        return catalog.map { item in
            let product = entitlements.products.first { $0.id == item.id }
            return PlanCard(
                id: item.id,
                title: product?.displayName ?? item.title,
                subtitle: {
                    if let description = product?.description, !description.isEmpty {
                        return description
                    }
                    return item.subtitle
                }(),
                priceLabel: product?.displayPrice ?? item.fallback
            )
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(FieldFolioTheme.accent)
                        Text("FieldFolio Pro")
                            .font(.largeTitle.weight(.bold))
                        Text("Unlimited clients and jobs, clean PDFs without a watermark, home-screen widget, and job reminders.")
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        feature("Unlimited clients & jobs")
                        feature("Clean, professional PDFs")
                        feature("Today widget")
                        feature("Job reminders")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FieldFolioTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    if entitlements.isLoadingProducts && entitlements.products.isEmpty {
                        ProgressView("Loading prices…")
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(plans) { plan in
                        Button {
                            Task { await buy(plan.id) }
                        } label: {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plan.title)
                                        .font(.headline)
                                    Text(plan.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer(minLength: 12)
                                if purchasingProductID == plan.id {
                                    ProgressView()
                                } else {
                                    Text(plan.priceLabel)
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(FieldFolioTheme.accent)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(FieldFolioTheme.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(purchasingProductID != nil)
                    }

                    if let error = entitlements.purchaseError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(FieldFolioTheme.danger)
                    }

                    Button("Restore purchases") {
                        Task {
                            await entitlements.restore()
                            if entitlements.isPro { dismiss() }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(purchasingProductID != nil)

                    Button("Retry loading prices") {
                        Task { await entitlements.loadProducts() }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(purchasingProductID != nil || entitlements.isLoadingProducts)

                    #if DEBUG
                    Button("Debug: unlock Pro") {
                        UserDefaults.standard.set(true, forKey: "FieldFolioDebugPro")
                        UserDefaults(suiteName: WidgetSnapshotWriter.suiteName)?
                            .set(true, forKey: "FieldFolioDebugPro")
                        Task {
                            await entitlements.refresh()
                            WidgetSnapshotWriter.setPro(true)
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    #endif

                    Text("Free includes 3 clients, 8 jobs, and watermarked PDFs. Cancel anytime in Settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await entitlements.loadProducts()
            }
        }
    }

    private func buy(_ productID: String) async {
        purchasingProductID = productID
        await entitlements.purchase(productID: productID)
        purchasingProductID = nil
        if entitlements.isPro {
            dismiss()
        }
    }

    private func feature(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .foregroundStyle(FieldFolioTheme.success)
    }
}
