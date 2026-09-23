import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetSnapshotWriter {
    static let suiteName = "group.com.fieldfolio.app"
    static let snapshotKey = "widgetSnapshot"
    static let isProKey = "isPro"
    static let snapshotFileName = "widget_snapshot.json"

    struct Snapshot: Codable {
        var nextJobTitle: String
        var nextJobTime: String
        var unpaidTotal: String
        var unpaidCount: Int
        var isPro: Bool
    }

    /// True when the App Group container is actually available (not a private-sandbox fallback).
    static var hasSharedContainer: Bool {
        containerURL() != nil
    }

    static func write(_ snapshot: Snapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }

        if let defaults = UserDefaults(suiteName: suiteName) {
            defaults.set(data, forKey: snapshotKey)
            defaults.set(snapshot.isPro, forKey: isProKey)
            defaults.synchronize()
        }

        if let url = containerFileURL() {
            try? data.write(to: url, options: .atomic)
        }

        refresh()
    }

    static func read() -> Snapshot? {
        if let data = UserDefaults(suiteName: suiteName)?.data(forKey: snapshotKey),
           let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) {
            return snapshot
        }
        if let url = containerFileURL(),
           let data = try? Data(contentsOf: url),
           let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) {
            return snapshot
        }
        return nil
    }

    static func readIsPro() -> Bool {
        if let defaults = UserDefaults(suiteName: suiteName),
           defaults.object(forKey: isProKey) != nil {
            return defaults.bool(forKey: isProKey)
        }
        return read()?.isPro ?? false
    }

    static func setPro(_ isPro: Bool) {
        var snapshot = read() ?? Snapshot(
            nextJobTitle: "No upcoming jobs",
            nextJobTime: "",
            unpaidTotal: "$0",
            unpaidCount: 0,
            isPro: false
        )
        snapshot.isPro = isPro
        write(snapshot)
    }

    static func refresh() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        WidgetCenter.shared.reloadTimelines(ofKind: "JobslipWidget")
        #endif
    }

    private static func containerURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
    }

    private static func containerFileURL() -> URL? {
        containerURL()?.appendingPathComponent(snapshotFileName)
    }
}
