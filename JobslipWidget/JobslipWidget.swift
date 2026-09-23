import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            nextJobTitle: "Garcia — Interior detail",
            nextJobTime: "9:00 AM",
            unpaidTotal: "$220",
            unpaidCount: 1,
            isPro: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = makeEntry()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        completion(timeline)
    }

    private func makeEntry() -> SimpleEntry {
        let snapshot = WidgetSnapshotWriter.read()
        #if DEBUG
        let debugPro = UserDefaults(suiteName: WidgetSnapshotWriter.suiteName)?
            .bool(forKey: "FieldFolioDebugPro") == true
        #else
        let debugPro = false
        #endif
        let isPro = (snapshot?.isPro ?? false)
            || WidgetSnapshotWriter.readIsPro()
            || debugPro

        if let snapshot {
            return SimpleEntry(
                date: Date(),
                nextJobTitle: snapshot.nextJobTitle,
                nextJobTime: snapshot.nextJobTime,
                unpaidTotal: snapshot.unpaidTotal,
                unpaidCount: snapshot.unpaidCount,
                isPro: isPro
            )
        }

        if isPro {
            return SimpleEntry(
                date: Date(),
                nextJobTitle: "No upcoming jobs",
                nextJobTime: "",
                unpaidTotal: "$0",
                unpaidCount: 0,
                isPro: true
            )
        }

        return SimpleEntry(
            date: Date(),
            nextJobTitle: "No upcoming jobs",
            nextJobTime: "",
            unpaidTotal: "$0",
            unpaidCount: 0,
            isPro: false
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let nextJobTitle: String
    let nextJobTime: String
    let unpaidTotal: String
    let unpaidCount: Int
    let isPro: Bool
}

struct JobslipWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FieldFolio")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            if entry.isPro {
                Text(entry.nextJobTitle)
                    .font(.headline)
                    .lineLimit(2)
                if !entry.nextJobTime.isEmpty {
                    Text(entry.nextJobTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                HStack {
                    Text("Unpaid")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(entry.unpaidCount == 0 ? "None" : entry.unpaidTotal)
                        .font(.subheadline.weight(.semibold))
                }
            } else {
                Text("Upgrade to Pro")
                    .font(.headline)
                Text("Unlock the Today widget.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct JobslipWidget: Widget {
    let kind = "JobslipWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            JobslipWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("FieldFolio Today")
        .description("Next job and unpaid total.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
