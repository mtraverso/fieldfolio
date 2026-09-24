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
                String(localized: "Monthly"),
                String(localized: "Unlimited everything. 7-day free trial."),
                "$4.99 / month"
            ),
            (
                EntitlementStore.yearlyID,
                String(localized: "Yearly"),
                String(localized: "Best value. 7-day free trial."),
                "$29.99 / year"
            ),
            (
                EntitlementStore.lifetimeID,
                String(localized: "Lifetime"),
                String(localized: "Pay once. Keep Pro forever."),
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
                        Text(String(localized: "FieldFolio Pro"))
                            .font(.largeTitle.weight(.bold))
                        Text(String(localized: "Unlimited clients and jobs, clean PDFs without a watermark, home-screen widget, and job reminders."))
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        feature(String(localized: "Unlimited clients & jobs"))
                        feature(String(localized: "Clean, professional PDFs"))
                        feature(String(localized: "Today widget"))
                        feature(String(localized: "Job reminders"))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FieldFolioTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    if entitlements.isLoadingProducts && entitlements.products.isEmpty {
                        ProgressView(String(localized: "Loading prices…"))
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

                    Button(String(localized: "Restore purchases")) {
                        Task {
                            await entitlements.restore()
                            if entitlements.isPro { dismiss() }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(purchasingProductID != nil)

                    Button(String(localized: "Retry loading prices")) {
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

                    Text(String(localized: "Free includes 3 clients, 8 jobs, and watermarked PDFs."))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(String(localized: "Payment is charged to your Apple ID at confirmation. Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel in Settings > Apple ID > Subscriptions. Lifetime is a one-time purchase."))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        Link(String(localized: "Terms of Use"), destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        Link(String(localized: "Privacy Policy"), destination: URL(string: "https://mtraverso.github.io/fieldfolio/privacy.html")!)
                    }
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle(String(localized: "Upgrade"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Close")) { dismiss() }
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
