import SwiftUI

enum FieldFolioTheme {
    static let accent = Color(red: 0.12, green: 0.45, blue: 0.72)
    static let success = Color(red: 0.15, green: 0.62, blue: 0.38)
    static let warning = Color(red: 0.85, green: 0.55, blue: 0.12)
    static let danger = Color(red: 0.78, green: 0.22, blue: 0.22)
    static let surface = Color(.secondarySystemBackground)
}

extension Decimal {
    func formatted(currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isThisWeek: Bool {
        let calendar = Calendar.current
        let now = Date()
        let selfWeek = calendar.component(.weekOfYear, from: self)
        let nowWeek = calendar.component(.weekOfYear, from: now)
        let selfYear = calendar.component(.yearForWeekOfYear, from: self)
        let nowYear = calendar.component(.yearForWeekOfYear, from: now)
        return selfWeek == nowWeek && selfYear == nowYear
    }
}
