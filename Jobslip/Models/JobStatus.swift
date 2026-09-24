import Foundation

enum JobStatus: String, Codable, CaseIterable, Identifiable {
    case estimate
    case scheduled
    case inProgress
    case done
    case invoiced
    case paid

    var id: String { rawValue }

    var label: String {
        switch self {
        case .estimate: return String(localized: "Estimate")
        case .scheduled: return String(localized: "Scheduled")
        case .inProgress: return String(localized: "In Progress")
        case .done: return String(localized: "Done")
        case .invoiced: return String(localized: "Invoiced")
        case .paid: return String(localized: "Paid")
        }
    }

    var systemImage: String {
        switch self {
        case .estimate: return "doc.text"
        case .scheduled: return "calendar"
        case .inProgress: return "wrench.and.screwdriver"
        case .done: return "checkmark.circle"
        case .invoiced: return "doc.richtext"
        case .paid: return "dollarsign.circle.fill"
        }
    }
}
