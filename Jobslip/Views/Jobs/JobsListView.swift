import SwiftUI
import SwiftData

struct JobsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Job.scheduledAt, order: .reverse) private var jobs: [Job]
    @Query private var clients: [Client]
    @Query private var profiles: [BusinessProfile]
    @EnvironmentObject private var entitlements: EntitlementStore

    @State private var showingNewJob = false
    @State private var showingPaywall = false
    @State private var filter: JobStatus? = nil

    private var currencyCode: String {
        profiles.first?.currencyCode ?? "USD"
    }

    private var filteredJobs: [Job] {
        guard let filter else { return jobs }
        return jobs.filter { $0.status == filter }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            FilterChip(title: "All", selected: filter == nil) { filter = nil }
                            ForEach(JobStatus.allCases) { status in
                                FilterChip(title: status.label, selected: filter == status) {
                                    filter = status
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                if filteredJobs.isEmpty {
                    EmptyStateView(
                        title: "No jobs yet",
                        message: "Add a job or estimate to get started.",
                        systemImage: "briefcase"
                    )
                } else {
                    ForEach(filteredJobs) { job in
                        NavigationLink {
                            JobDetailView(job: job)
                        } label: {
                            JobRowView(job: job, currencyCode: currencyCode)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Jobs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if entitlements.canAddJob(currentCount: jobs.count) {
                            showingNewJob = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewJob) {
                JobEditorView(job: nil)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let job = filteredJobs[index]
            NotificationService.cancelJobReminder(jobID: job.id)
            modelContext.delete(job)
        }
    }
}

private struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? FieldFolioTheme.accent : FieldFolioTheme.surface)
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
