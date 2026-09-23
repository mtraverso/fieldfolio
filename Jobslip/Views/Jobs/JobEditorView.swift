import SwiftUI
import SwiftData

struct JobEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlements: EntitlementStore
    @Query(sort: \Client.name) private var clients: [Client]
    @Query private var profiles: [BusinessProfile]

    let job: Job?

    private enum ClientMode: String, CaseIterable, Identifiable {
        case existing
        case new

        var id: String { rawValue }

        var label: String {
            switch self {
            case .existing: return "Existing"
            case .new: return "New client"
            }
        }
    }

    @State private var serviceName = ""
    @State private var amountText = ""
    @State private var notes = ""
    @State private var scheduledAt = Date()
    @State private var selectedClientID: UUID?
    @State private var asEstimate = false
    @State private var clientMode: ClientMode = .existing
    @State private var newClientName = ""
    @State private var newClientPhone = ""
    @State private var newClientAddress = ""
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    if job == nil {
                        Picker("Client", selection: $clientMode) {
                            ForEach(ClientMode.allCases) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if clientMode == .existing || job != nil {
                        if clients.isEmpty {
                            Text("No clients yet. Switch to New client.")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Client", selection: $selectedClientID) {
                                Text("Select").tag(UUID?.none)
                                ForEach(clients) { client in
                                    Text(client.name).tag(Optional(client.id))
                                }
                            }
                        }
                    } else {
                        TextField("Name", text: $newClientName)
                        TextField("Phone", text: $newClientPhone)
                            .keyboardType(.phonePad)
                        TextField("Address", text: $newClientAddress)
                    }
                }
                .onChange(of: clientMode) { _, mode in
                    if mode == .existing, selectedClientID == nil, let first = clients.first {
                        selectedClientID = first.id
                        if amountText.isEmpty, first.defaultRate > 0 {
                            amountText = "\(first.defaultRate)"
                        }
                    }
                }
                .onChange(of: selectedClientID) { _, id in
                    guard let id,
                          let client = clients.first(where: { $0.id == id }),
                          job == nil,
                          amountText.isEmpty,
                          client.defaultRate > 0
                    else { return }
                    amountText = "\(client.defaultRate)"
                }

                Section("Job") {
                    TextField("Service name", text: $serviceName)
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    DatePicker("When", selection: $scheduledAt)
                    if job == nil {
                        Toggle("Save as estimate", isOn: $asEstimate)
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(job == nil ? "New job" : "Edit job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if let job {
                    serviceName = job.serviceName
                    amountText = "\(job.amount)"
                    notes = job.notes
                    scheduledAt = job.scheduledAt
                    selectedClientID = job.client?.id
                    asEstimate = job.status == .estimate
                    clientMode = .existing
                } else if clients.isEmpty {
                    clientMode = .new
                } else if let first = clients.first {
                    selectedClientID = first.id
                    if first.defaultRate > 0 {
                        amountText = "\(first.defaultRate)"
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private var canSave: Bool {
        let hasService = !serviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAmount = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) != nil
        let hasClient: Bool = {
            if clientMode == .new && job == nil {
                return !newClientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return selectedClientID != nil
        }()
        return hasService && hasAmount && hasClient
    }

    private func resolveClient() -> Client? {
        if job != nil || clientMode == .existing {
            guard let clientID = selectedClientID else { return nil }
            return clients.first(where: { $0.id == clientID })
        }

        if !entitlements.canAddClient(currentCount: clients.count) {
            showingPaywall = true
            return nil
        }

        let created = Client(
            name: newClientName.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: newClientPhone.trimmingCharacters(in: .whitespacesAndNewlines),
            address: newClientAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        modelContext.insert(created)
        return created
    }

    private func save() {
        guard let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")),
              let client = resolveClient()
        else { return }

        let target = job ?? {
            let created = Job(
                serviceName: serviceName,
                amount: amount,
                notes: notes,
                status: asEstimate ? .estimate : .scheduled,
                scheduledAt: scheduledAt,
                client: client
            )
            modelContext.insert(created)
            return created
        }()

        target.serviceName = serviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        target.amount = amount
        target.notes = notes
        target.scheduledAt = scheduledAt
        target.client = client

        if job == nil, asEstimate, let profile = profiles.first {
            target.estimateNumber = profile.nextEstimateNumber
            profile.nextEstimateNumber += 1
            target.status = .estimate
        }

        if target.status == .scheduled || target.status == .estimate {
            NotificationService.scheduleJobReminder(
                jobID: target.id,
                title: "\(client.name) — \(target.serviceName)",
                at: scheduledAt
            )
        }

        try? modelContext.save()
        WidgetSnapshotWriter.refresh()
        dismiss()
    }
}

extension Client: Identifiable {}
