import Foundation

/// How often the desktop should be cleaned.
enum Frequency: String, CaseIterable, Identifiable, Codable {
    case daily
    case weekly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .daily:  return "Every day"
        case .weekly: return "Every week"
        }
    }

    /// Whether a clean is due, given the last clean date.
    ///
    /// With daily cleaning a clean is due once the calendar day changes; with
    /// weekly cleaning it's due when the last clean is 7+ days old.
    /// If the desktop has never been cleaned, a clean is always due.
    func shouldClean(lastClean: Date?, now: Date, calendar: Calendar = .current) -> Bool {
        guard let last = lastClean else { return true }
        switch self {
        case .daily:
            return !calendar.isDate(last, inSameDayAs: now)
        case .weekly:
            // Compare calendar-day boundaries (not elapsed wall-clock time), so a
            // weekly clean fires once 7 calendar days have passed regardless of the
            // time of day the last clean happened — consistent with the daily case.
            let startLast = calendar.startOfDay(for: last)
            let startNow = calendar.startOfDay(for: now)
            guard let days = calendar.dateComponents([.day], from: startLast, to: startNow).day else { return true }
            return days >= 7
        }
    }
}
