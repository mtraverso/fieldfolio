import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BusinessProfile]
    @State private var businessName = ""
    @State private var phone = ""
    @State private var currencyCode = "USD"

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "MXN", "BRL", "ARS"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "doc.text.image.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(FieldFolioTheme.accent)
                        Text("Job book for people who show up and get paid.")
                            .font(.title2.weight(.bold))
                        Text("Track jobs, before/after photos, estimates, and invoices — all on your phone. No account.")
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 8)
                }

                Section("Your business") {
                    TextField("Business name", text: $businessName)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencies, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                }

                Section {
                    Button {
                        finish()
                    } label: {
                        Text("Get started")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .disabled(businessName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Welcome to FieldFolio")
            .onAppear {
                if let profile = profiles.first {
                    businessName = profile.businessName
                    phone = profile.phone
                    currencyCode = profile.currencyCode
                }
            }
        }
    }

    private func finish() {
        let profile = profiles.first ?? {
            let created = BusinessProfile()
            modelContext.insert(created)
            return created
        }()
        profile.businessName = businessName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.currencyCode = currencyCode
        profile.hasCompletedOnboarding = true
        NotificationService.requestPermission()
        try? modelContext.save()
    }
}
