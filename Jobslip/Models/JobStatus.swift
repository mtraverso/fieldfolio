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
        case .estimate: return "Estimate"
        case .scheduled: return "Scheduled"
        case .inProgress: return "In Progress"
        case .done: return "Done"
        case .invoiced: return "Invoiced"
        case .paid: return "Paid"
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
