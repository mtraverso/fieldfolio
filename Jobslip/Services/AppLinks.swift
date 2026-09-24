import Foundation

enum AppLinks {
    private static let base = "https://mtraverso.github.io/fieldfolio/docs/"

    private static var localePrefix: String {
        Bundle.main.preferredLocalizations.first?.hasPrefix("es") == true ? "es/" : ""
    }

    static var privacy: URL { URL(string: base + localePrefix + "privacy.html")! }
    static var support: URL { URL(string: base + localePrefix + "support.html")! }
}
