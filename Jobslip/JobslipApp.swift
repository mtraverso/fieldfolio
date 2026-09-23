import SwiftUI
import SwiftData

@main
struct JobslipApp: App {
    @StateObject private var entitlements = EntitlementStore()
    @State private var isUnlocked = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Client.self,
            Job.self,
            JobPhoto.self,
            BusinessProfile.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView(isUnlocked: $isUnlocked)
                .environmentObject(entitlements)
                .modelContainer(sharedModelContainer)
                .task {
                    SampleDataSeeder.seedIfNeeded(context: sharedModelContainer.mainContext)
                    await entitlements.refresh()
                }
        }
    }
}

struct RootView: View {
    @Binding var isUnlocked: Bool
    @Query private var profiles: [BusinessProfile]
    @State private var checkedLock = false

    private var profile: BusinessProfile? { profiles.first }
    private var needsOnboarding: Bool {
        !(profile?.hasCompletedOnboarding ?? false)
    }

    var body: some View {
        Group {
            if needsOnboarding {
                OnboardingView()
            } else if profile?.faceIDEnabled == true && !isUnlocked {
                LockScreen(isUnlocked: $isUnlocked)
            } else {
                ContentView()
            }
        }
        .task {
            if profile?.faceIDEnabled != true {
                isUnlocked = true
            }
        }
    }
}

struct LockScreen: View {
    @Binding var isUnlocked: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(FieldFolioTheme.accent)
            Text("FieldFolio is locked")
                .font(.title2.weight(.bold))
            Button("Unlock") {
                Task {
                    isUnlocked = await BiometricLock.authenticate()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            isUnlocked = await BiometricLock.authenticate()
        }
    }
}
