import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BusinessProfile]
    @Query private var clients: [Client]
    @Query private var jobs: [Job]
    @EnvironmentObject private var entitlements: EntitlementStore

    @State private var showingPaywall = false
    @State private var businessName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var currencyCode = "USD"
    @State private var paymentInstructions = ""
    @State private var faceIDEnabled = false
    @State private var exportURL: URL?
    @State private var showingExportShare = false
    @State private var exportError: String?
    @State private var confirmingRemoveSamples = false

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "MXN", "BRL", "ARS"]

    private var profile: BusinessProfile? { profiles.first }

    private var billableClientCount: Int {
        clients.filter { !$0.isSample }.count
    }

    private var billableJobCount: Int {
        jobs.filter { !$0.isSample }.count
    }

    private var hasSampleData: Bool {
        SampleDataSeeder.hasSampleData(clients: clients, jobs: jobs)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Business")) {
                    TextField(String(localized: "Business name"), text: $businessName)
                    TextField(String(localized: "Phone"), text: $phone)
                        .keyboardType(.phonePad)
                    TextField(String(localized: "Email"), text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    Picker(String(localized: "Currency"), selection: $currencyCode) {
                        ForEach(currencies, id: \.self) { Text($0).tag($0) }
                    }
                    TextField(String(localized: "How to pay (e.g. Venmo @maria · Zelle 555-0100)"), text: $paymentInstructions, axis: .vertical)
                        .lineLimit(2...4)
                    Button(String(localized: "Save business profile")) { saveProfile() }
                }

                Section(String(localized: "Security")) {
                    Toggle(String(localized: "Require Face ID / Touch ID"), isOn: $faceIDEnabled)
                        .onChange(of: faceIDEnabled) { _, newValue in
                            profile?.faceIDEnabled = newValue
                            try? modelContext.save()
                        }
                }

                Section(String(localized: "Backup")) {
                    Button(String(localized: "Export backup")) {
                        exportBackup()
                    }
                    Text(String(localized: "Creates a ZIP with CSV data and job photos. Stays on your device until you share it."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let exportError {
                        Text(exportError)
                            .font(.footnote)
                            .foregroundStyle(FieldFolioTheme.danger)
                    }
                }

                if hasSampleData {
                    Section(String(localized: "Sample data")) {
                        Text(String(localized: "Demo clients and jobs help you explore the app. They don’t count toward Free limits."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button(String(localized: "Remove sample data"), role: .destructive) {
                            confirmingRemoveSamples = true
                        }
                    }
                }

                Section(String(localized: "FieldFolio Pro")) {
                    if entitlements.isPro {
                        Label(String(localized: "Pro unlocked"), systemImage: "checkmark.seal.fill")
                            .foregroundStyle(FieldFolioTheme.success)
                    } else {
                        Text(String(localized: "Free: \(billableClientCount)/\(EntitlementStore.freeClientLimit) clients · \(billableJobCount)/\(EntitlementStore.freeJobLimit) jobs"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button(String(localized: "Upgrade to Pro")) { showingPaywall = true }
                    }
                    Button(String(localized: "Restore purchases")) {
                        Task { await entitlements.restore() }
                    }
                }

                Section(String(localized: "About")) {
                    LabeledContent(String(localized: "Version"), value: appVersion)
                    Link(String(localized: "Privacy"), destination: AppLinks.privacy)
                    Link(String(localized: "Support"), destination: AppLinks.support)
                    Text(String(localized: "Invoices are records, not tax or legal advice."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(String(localized: "Settings"))
            .onAppear { load() }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingExportShare) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
            .confirmationDialog(
                String(localized: "Remove sample data?"),
                isPresented: $confirmingRemoveSamples,
                titleVisibility: .visible
            ) {
                Button(String(localized: "Remove sample data"), role: .destructive) {
                    SampleDataSeeder.removeSampleData(context: modelContext, clients: clients, jobs: jobs)
                }
                Button(String(localized: "Cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "This deletes the demo clients, jobs, and photos. Your own records stay."))
            }
        }
    }

    private func load() {
        guard let profile else { return }
        businessName = profile.businessName
        phone = profile.phone
        email = profile.email
        currencyCode = profile.currencyCode
        paymentInstructions = profile.paymentInstructions
        faceIDEnabled = profile.faceIDEnabled
    }

    private func saveProfile() {
        guard let profile else { return }
        profile.businessName = businessName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.currencyCode = currencyCode
        profile.paymentInstructions = paymentInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        try? modelContext.save()
    }

    private func exportBackup() {
        exportError = nil
        do {
            let url = try DataExporter.exportBackup(clients: clients, jobs: jobs, profile: profile)
            exportURL = url
            showingExportShare = true
        } catch {
            exportError = error.localizedDescription
        }
    }
}
