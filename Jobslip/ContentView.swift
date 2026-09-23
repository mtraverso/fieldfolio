import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    @Query(sort: \Job.scheduledAt) private var jobs: [Job]
    @Query private var profiles: [BusinessProfile]
    @EnvironmentObject private var entitlements: EntitlementStore

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            JobsListView()
                .tabItem { Label("Jobs", systemImage: "briefcase.fill") }

            ClientsListView()
                .tabItem { Label("Clients", systemImage: "person.2.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(FieldFolioTheme.accent)
        .onAppear { pushWidgetSnapshot() }
        // Count alone misses mark-paid / status edits — fingerprint covers those.
        .onChange(of: widgetSyncKey) { _, _ in pushWidgetSnapshot() }
        .onChange(of: entitlements.isPro) { _, _ in pushWidgetSnapshot() }
        .onChange(of: entitlements.hasResolvedEntitlements) { _, resolved in
            if resolved { pushWidgetSnapshot() }
        }
        .onReceive(entitlements.$isPro) { _ in
            pushWidgetSnapshot()
        }
    }

    /// Invalidates whenever a job’s status, amount, schedule, or identity changes.
    private var widgetSyncKey: String {
        jobs.map { job in
            "\(job.persistentModelID)|\(job.statusRaw)|\(NSDecimalNumber(decimal: job.amount).stringValue)|\(job.scheduledAt.timeIntervalSince1970)"
        }
        .joined(separator: ";")
    }

    private func pushWidgetSnapshot() {
        // Avoid clobbering a true Pro flag with false before StoreKit/debug unlock resolves.
        guard entitlements.hasResolvedEntitlements || entitlements.isPro else { return }

        let currency = profiles.first?.currencyCode ?? "USD"
        let upcoming = jobs
            .filter { $0.status == .scheduled || $0.status == .inProgress }
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .first
        let unpaid = jobs.filter { $0.status == .invoiced }
        let unpaidTotal = unpaid.reduce(Decimal(0)) { $0 + $1.amount }

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .short

        WidgetSnapshotWriter.write(
            .init(
                nextJobTitle: upcoming.map { "\($0.client?.name ?? "Client") — \($0.serviceName)" } ?? "No upcoming jobs",
                nextJobTime: upcoming.map { timeFormatter.string(from: $0.scheduledAt) } ?? "",
                unpaidTotal: unpaidTotal.formatted(currencyCode: currency),
                unpaidCount: unpaid.count,
                isPro: entitlements.isPro
            )
        )
    }
}
