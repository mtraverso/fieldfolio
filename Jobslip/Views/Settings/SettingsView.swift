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
    @State private var faceIDEnabled = false

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "MXN", "BRL", "ARS"]

    private var profile: BusinessProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Form {
                Section("Business") {
                    TextField("Business name", text: $businessName)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencies, id: \.self) { Text($0).tag($0) }
                    }
                    Button("Save business profile") { saveProfile() }
                }

                Section("Security") {
                    Toggle("Require Face ID / Touch ID", isOn: $faceIDEnabled)
                        .onChange(of: faceIDEnabled) { _, newValue in
                            profile?.faceIDEnabled = newValue
                            try? modelContext.save()
                        }
                }

                Section("FieldFolio Pro") {
                    if entitlements.isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(FieldFolioTheme.success)
                    } else {
                        Text("Free: \(clients.count)/\(EntitlementStore.freeClientLimit) clients · \(jobs.count)/\(EntitlementStore.freeJobLimit) jobs")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Upgrade to Pro") { showingPaywall = true }
                    }
                    Button("Restore purchases") {
                        Task { await entitlements.restore() }
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    Link("Privacy", destination: URL(string: "https://mtraverso.github.io/fieldfolio/privacy.html")!)
                    Link("Support", destination: URL(string: "https://mtraverso.github.io/fieldfolio/support.html")!)
                    Text("Invoices are records, not tax or legal advice.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .onAppear { load() }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private func load() {
        guard let profile else { return }
        businessName = profile.businessName
        phone = profile.phone
        email = profile.email
        currencyCode = profile.currencyCode
        faceIDEnabled = profile.faceIDEnabled
    }

    private func saveProfile() {
        guard let profile else { return }
        profile.businessName = businessName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.currencyCode = currencyCode
        try? modelContext.save()
    }
}
