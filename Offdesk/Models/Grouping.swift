import Foundation

/// How cleaned items are grouped into subfolders inside the destination.
///
/// Grouping uses the *clean date* (the moment the clean runs), matching the
/// original RINIK behaviour where each month's folder is created the first time
/// a clean happens that month.
enum Grouping: String, CaseIterable, Identifiable, Codable {
    case none
    case month
    case day

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none:  return "Don't group (one folder)"
        case .month: return "Group by month"
        case .day:   return "Group by day"
        }
    }

    /// The subfolder name for a given date, or `nil` when items should not be grouped.
    /// Examples: month -> "2026 June", day -> "2026 June 04".
    func subfolderName(for date: Date) -> String? {
        switch self {
        case .none:  return nil
        case .month: return Self.monthFormatter.string(from: date)
        case .day:   return Self.dayFormatter.string(from: date)
        }
    }

    // Fixed, locale-independent formatting so folder names stay stable ("June", not a localized month).
    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy LLLL"
        return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy LLLL dd"
        return f
    }()
}
