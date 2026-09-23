import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Job.scheduledAt) private var jobs: [Job]
    @Query private var profiles: [BusinessProfile]
    @EnvironmentObject private var entitlements: EntitlementStore

    private var currencyCode: String {
        profiles.first?.currencyCode ?? "USD"
    }

    private var todaysJobs: [Job] {
        jobs.filter { $0.scheduledAt.isToday && $0.status != .paid && $0.status != .estimate }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    private var unpaidCount: Int {
        jobs.filter { $0.status == .invoiced }.count
    }

    private var collectedThisWeek: Decimal {
        jobs
            .filter { $0.status == .paid && ($0.completedAt ?? $0.scheduledAt).isThisWeek }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        MoneyStatCard(
                            title: "This week",
                            value: collectedThisWeek.formatted(currencyCode: currencyCode),
                            systemImage: "banknote",
                            tint: FieldFolioTheme.success
                        )
                        MoneyStatCard(
                            title: "Unpaid",
                            value: "\(unpaidCount)",
                            systemImage: "exclamationmark.bubble",
                            tint: unpaidCount > 0 ? FieldFolioTheme.warning : FieldFolioTheme.success
                        )
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                Section("Today's jobs") {
                    if todaysJobs.isEmpty {
                        Text("No jobs scheduled today.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(todaysJobs) { job in
                            NavigationLink(value: job.id) {
                                JobRowView(job: job, currencyCode: currencyCode)
                            }
                        }
                    }
                }

                if unpaidCount > 0 {
                    Section("Needs payment") {
                        ForEach(jobs.filter { $0.status == .invoiced }) { job in
                            NavigationLink(value: job.id) {
                                JobRowView(job: job, currencyCode: currencyCode)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Today")
            .navigationDestination(for: UUID.self) { id in
                if let job = jobs.first(where: { $0.id == id }) {
                    JobDetailView(job: job)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if entitlements.isPro {
                        Label("Pro", systemImage: "checkmark.seal.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(FieldFolioTheme.accent)
                    }
                }
            }
        }
    }
}

struct JobRowView: View {
    let job: Job
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(job.client?.name ?? "No client")
                    .font(.headline)
                Spacer()
                Text(job.amount.formatted(currencyCode: currencyCode))
                    .font(.subheadline.weight(.semibold))
            }
            Text(job.serviceName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                StatusBadge(status: job.status)
                Spacer()
                Text(job.scheduledAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

extension Job: Identifiable {}
