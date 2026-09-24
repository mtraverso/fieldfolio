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
            case .existing: return String(localized: "Existing")
            case .new: return String(localized: "New client")
            }
        }
    }

    private struct DraftLine: Identifiable {
        let id: UUID
        var title: String
        var quantityText: String
        var unitPriceText: String

        init(
            id: UUID = UUID(),
            title: String = "",
            quantityText: String = "1",
            unitPriceText: String = ""
        ) {
            self.id = id
            self.title = title
            self.quantityText = quantityText
            self.unitPriceText = unitPriceText
        }

        var quantity: Decimal {
            Decimal(string: quantityText.replacingOccurrences(of: ",", with: ".")) ?? 0
        }

        var unitPrice: Decimal {
            Decimal(string: unitPriceText.replacingOccurrences(of: ",", with: ".")) ?? 0
        }

        var lineTotal: Decimal { quantity * unitPrice }
    }

    @State private var lines: [DraftLine] = [DraftLine()]
    @State private var taxPercentText = ""
    @State private var discountText = ""
    @State private var notes = ""
    @State private var scheduledAt = Date()
    @State private var selectedClientID: UUID?
    @State private var asEstimate = false
    @State private var clientMode: ClientMode = .existing
    @State private var newClientName = ""
    @State private var newClientPhone = ""
    @State private var newClientAddress = ""
    @State private var showingPaywall = false

    private var currencyCode: String {
        profiles.first?.currencyCode ?? "USD"
    }

    private var draftSubtotal: Decimal {
        lines.reduce(Decimal(0)) { $0 + $1.lineTotal }
    }

    private var draftDiscount: Decimal {
        Decimal(string: discountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var draftTaxPercent: Decimal {
        Decimal(string: taxPercentText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var draftTax: Decimal {
        max(draftSubtotal - draftDiscount, 0) * draftTaxPercent / 100
    }

    private var draftTotal: Decimal {
        max(draftSubtotal - draftDiscount, 0) + draftTax
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Client")) {
                    if job == nil {
                        Picker(String(localized: "Client"), selection: $clientMode) {
                            ForEach(ClientMode.allCases) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if clientMode == .existing || job != nil {
                        if clients.isEmpty {
                            Text(String(localized: "No clients yet. Switch to New client."))
                                .foregroundStyle(.secondary)
                        } else {
                            Picker(String(localized: "Client"), selection: $selectedClientID) {
                                Text(String(localized: "Select")).tag(UUID?.none)
                                ForEach(clients) { client in
                                    Text(client.name).tag(Optional(client.id))
                                }
                            }
                        }
                    } else {
                        TextField(String(localized: "Name"), text: $newClientName)
                        TextField(String(localized: "Phone"), text: $newClientPhone)
                            .keyboardType(.phonePad)
                        TextField(String(localized: "Address"), text: $newClientAddress)
                    }
                }
                .onChange(of: clientMode) { _, mode in
                    if mode == .existing, selectedClientID == nil, let first = clients.first {
                        selectedClientID = first.id
                        applyDefaultRate(from: first)
                    }
                }
                .onChange(of: selectedClientID) { _, id in
                    guard let id,
                          let client = clients.first(where: { $0.id == id }),
                          job == nil
                    else { return }
                    applyDefaultRate(from: client)
                }

                Section(String(localized: "Line items")) {
                    ForEach($lines) { $line in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField(String(localized: "Description"), text: $line.title)
                            HStack {
                                TextField(String(localized: "Qty"), text: $line.quantityText)
                                    .keyboardType(.decimalPad)
                                    .frame(maxWidth: 72)
                                TextField(String(localized: "Unit price"), text: $line.unitPriceText)
                                    .keyboardType(.decimalPad)
                                Text(line.lineTotal.formatted(currencyCode: currencyCode))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { offsets in
                        lines.remove(atOffsets: offsets)
                        if lines.isEmpty { lines = [DraftLine()] }
                    }

                    Button {
                        lines.append(DraftLine())
                    } label: {
                        Label(String(localized: "Add line"), systemImage: "plus.circle.fill")
                    }
                }

                Section(String(localized: "Totals")) {
                    TextField(String(localized: "Tax %"), text: $taxPercentText)
                        .keyboardType(.decimalPad)
                    TextField(String(localized: "Discount"), text: $discountText)
                        .keyboardType(.decimalPad)
                    LabeledContent(String(localized: "Subtotal"), value: draftSubtotal.formatted(currencyCode: currencyCode))
                    if draftDiscount > 0 {
                        LabeledContent(String(localized: "Discount"), value: "−\(draftDiscount.formatted(currencyCode: currencyCode))")
                    }
                    if draftTaxPercent > 0 {
                        LabeledContent(String(localized: "Tax"), value: draftTax.formatted(currencyCode: currencyCode))
                    }
                    LabeledContent(String(localized: "Total"), value: draftTotal.formatted(currencyCode: currencyCode))
                        .font(.body.weight(.semibold))
                }

                Section(String(localized: "Schedule")) {
                    DatePicker(String(localized: "When"), selection: $scheduledAt)
                    if job == nil {
                        Toggle(String(localized: "Save as estimate"), isOn: $asEstimate)
                    }
                }

                Section(String(localized: "Notes")) {
                    TextField(String(localized: "Notes"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(job == nil ? String(localized: "New job") : String(localized: "Edit job"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear { load() }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private var canSave: Bool {
        let hasLines = lines.contains {
            !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.unitPrice >= 0 && $0.quantity > 0
        }
        let hasClient: Bool = {
            if clientMode == .new && job == nil {
                return !newClientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return selectedClientID != nil
        }()
        return hasLines && hasClient
    }

    private func applyDefaultRate(from client: Client) {
        guard client.defaultRate > 0 else { return }
        if lines.count == 1, lines[0].unitPriceText.isEmpty {
            lines[0].unitPriceText = "\(client.defaultRate)"
            if lines[0].title.isEmpty {
                lines[0].title = String(localized: "Service")
            }
        }
    }

    private func load() {
        if let job {
            notes = job.notes
            scheduledAt = job.scheduledAt
            selectedClientID = job.client?.id
            asEstimate = job.status == .estimate
            clientMode = .existing
            taxPercentText = job.taxPercent == 0 ? "" : "\(job.taxPercent)"
            discountText = job.discountAmount == 0 ? "" : "\(job.discountAmount)"

            let existing = job.sortedLineItems
            if existing.isEmpty {
                lines = [
                    DraftLine(
                        title: job.serviceName,
                        quantityText: "1",
                        unitPriceText: job.amount == 0 ? "" : "\(job.amount)"
                    )
                ]
            } else {
                lines = existing.map {
                    DraftLine(
                        id: $0.id,
                        title: $0.title,
                        quantityText: "\($0.quantity)",
                        unitPriceText: "\($0.unitPrice)"
                    )
                }
            }
        } else if clients.isEmpty {
            clientMode = .new
        } else if let first = clients.first {
            selectedClientID = first.id
            applyDefaultRate(from: first)
        }
    }

    private func resolveClient() -> Client? {
        if job != nil || clientMode == .existing {
            guard let clientID = selectedClientID else { return nil }
            return clients.first(where: { $0.id == clientID })
        }

        if !entitlements.canAddClient(currentCount: clients.filter { !$0.isSample }.count) {
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
        guard let client = resolveClient() else { return }

        let validLines = lines.filter {
            !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.quantity > 0
        }
        guard !validLines.isEmpty else { return }

        let target = job ?? {
            let created = Job(
                serviceName: validLines[0].title,
                amount: 0,
                notes: notes,
                status: asEstimate ? .estimate : .scheduled,
                scheduledAt: scheduledAt,
                client: client
            )
            modelContext.insert(created)
            return created
        }()

        target.notes = notes
        target.scheduledAt = scheduledAt
        target.client = client
        target.taxPercent = draftTaxPercent
        target.discountAmount = draftDiscount

        for item in target.lineItems {
            modelContext.delete(item)
        }
        target.lineItems = []

        for (index, draft) in validLines.enumerated() {
            let item = JobLineItem(
                title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                quantity: draft.quantity,
                unitPrice: draft.unitPrice,
                sortIndex: index,
                job: target
            )
            modelContext.insert(item)
            target.lineItems.append(item)
        }

        target.recalculateTotals()

        if job == nil, asEstimate, let profile = profiles.first {
            target.estimateNumber = profile.nextEstimateNumber
            profile.nextEstimateNumber += 1
            target.status = .estimate
        }

        if entitlements.isPro, target.status == .scheduled || target.status == .estimate {
            NotificationService.scheduleJobReminder(
                jobID: target.id,
                title: "\(client.name) — \(target.serviceName)",
                at: scheduledAt
            )
        } else {
            NotificationService.cancelJobReminder(jobID: target.id)
        }

        try? modelContext.save()
        WidgetSnapshotWriter.refresh()
        dismiss()
    }
}

extension Client: Identifiable {}
