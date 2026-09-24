import SwiftUI
import SwiftData

struct ClientsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Client.name) private var clients: [Client]
    @Query private var profiles: [BusinessProfile]
    @EnvironmentObject private var entitlements: EntitlementStore

    @State private var showingNew = false
    @State private var showingPaywall = false

    private var currencyCode: String {
        profiles.first?.currencyCode ?? "USD"
    }

    var body: some View {
        NavigationStack {
            List {
                if clients.isEmpty {
                    EmptyStateView(
                        title: String(localized: "No clients"),
                        message: String(localized: "Add the people you already work for."),
                        systemImage: "person.2"
                    )
                } else {
                    ForEach(clients) { client in
                        NavigationLink {
                            ClientDetailView(client: client)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(client.name).font(.headline)
                                if !client.phone.isEmpty {
                                    Text(client.phone)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                if client.defaultRate > 0 {
                                    Text(String(localized: "Default \(client.defaultRate.formatted(currencyCode: currencyCode))"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle(String(localized: "Clients"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if entitlements.canAddClient(currentCount: clients.filter { !$0.isSample }.count) {
                            showingNew = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNew) {
                ClientEditorView(client: nil)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(clients[index])
        }
    }
}

struct ClientDetailView: View {
    @Query private var profiles: [BusinessProfile]
    @Bindable var client: Client
    @State private var showingEditor = false

    private var currencyCode: String {
        profiles.first?.currencyCode ?? "USD"
    }

    private var sortedJobs: [Job] {
        client.jobs.sorted { $0.scheduledAt > $1.scheduledAt }
    }

    var body: some View {
        List {
            Section {
                LabeledContent(String(localized: "Phone"), value: client.phone.isEmpty ? "—" : client.phone)
                LabeledContent(String(localized: "Address"), value: client.address.isEmpty ? "—" : client.address)
                LabeledContent(
                    String(localized: "Default rate"),
                    value: client.defaultRate > 0
                        ? client.defaultRate.formatted(currencyCode: currencyCode)
                        : "—"
                )
                if !client.notes.isEmpty {
                    Text(client.notes)
                }
            }

            if !client.phone.isEmpty {
                Section {
                    if let url = URL(string: "tel:\(client.phone.filter(\.isNumber))") {
                        Link(destination: url) {
                            Label(String(localized: "Call"), systemImage: "phone.fill")
                        }
                    }
                    if let url = URL(string: "sms:\(client.phone.filter(\.isNumber))") {
                        Link(destination: url) {
                            Label(String(localized: "Message"), systemImage: "message.fill")
                        }
                    }
                }
            }

            Section(String(localized: "Jobs")) {
                if sortedJobs.isEmpty {
                    Text(String(localized: "No jobs yet."))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedJobs) { job in
                        NavigationLink {
                            JobDetailView(job: job)
                        } label: {
                            JobRowView(job: job, currencyCode: currencyCode)
                        }
                    }
                }
            }
        }
        .navigationTitle(client.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "Edit")) { showingEditor = true }
            }
        }
        .sheet(isPresented: $showingEditor) {
            ClientEditorView(client: client)
        }
    }
}

struct ClientEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let client: Client?

    @State private var name = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var defaultRateText = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Client")) {
                    TextField(String(localized: "Name"), text: $name)
                    TextField(String(localized: "Phone"), text: $phone)
                        .keyboardType(.phonePad)
                    TextField(String(localized: "Address"), text: $address)
                    TextField(String(localized: "Default rate"), text: $defaultRateText)
                        .keyboardType(.decimalPad)
                }
                Section(String(localized: "Notes")) {
                    TextField(String(localized: "Notes"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(client == nil ? String(localized: "New client") : String(localized: "Edit client"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let client {
                    name = client.name
                    phone = client.phone
                    address = client.address
                    defaultRateText = client.defaultRate > 0 ? "\(client.defaultRate)" : ""
                    notes = client.notes
                }
            }
        }
    }

    private func save() {
        let rate = Decimal(string: defaultRateText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let target = client ?? {
            let created = Client(name: name)
            modelContext.insert(created)
            return created
        }()
        target.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        target.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        target.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        target.defaultRate = rate
        target.notes = notes
        try? modelContext.save()
        dismiss()
    }
}
