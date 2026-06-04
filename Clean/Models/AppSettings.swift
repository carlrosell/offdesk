import Foundation
import SwiftUI

/// User-configurable settings, persisted to `UserDefaults`. Observable so SwiftUI
/// views update when values change. Property observers write through to defaults;
/// note that Swift does not call `didSet` for the initial assignments in `init`,
/// so loading from defaults does not redundantly write back.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    @Published var destinationPath: String { didSet { defaults.set(destinationPath, forKey: Keys.destination) } }
    @Published var sourcePaths: [String] { didSet { defaults.set(sourcePaths, forKey: Keys.sources) } }
    @Published var grouping: Grouping { didSet { defaults.set(grouping.rawValue, forKey: Keys.grouping) } }
    @Published var frequency: Frequency { didSet { defaults.set(frequency.rawValue, forKey: Keys.frequency) } }
    @Published var skipLabeled: Bool { didSet { defaults.set(skipLabeled, forKey: Keys.skipLabeled) } }
    @Published var launchAtLogin: Bool { didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) } }
    @Published var showNotifications: Bool { didSet { defaults.set(showNotifications, forKey: Keys.showNotifications) } }
    @Published var cleaningEnabled: Bool { didSet { defaults.set(cleaningEnabled, forKey: Keys.cleaningEnabled) } }
    @Published var lastCleanDate: Date? {
        didSet {
            if let date = lastCleanDate { defaults.set(date, forKey: Keys.lastClean) }
            else { defaults.removeObject(forKey: Keys.lastClean) }
        }
    }

    private enum Keys {
        static let destination = "destinationPath"
        static let sources = "sourcePaths"
        static let grouping = "grouping"
        static let frequency = "frequency"
        static let skipLabeled = "skipLabeled"
        static let launchAtLogin = "launchAtLogin"
        static let showNotifications = "showNotifications"
        static let cleaningEnabled = "cleaningEnabled"
        static let lastClean = "lastCleanDate"
    }

    private init() {
        let d = UserDefaults.standard
        let home = FileManager.default.homeDirectoryForCurrentUser
        destinationPath = d.string(forKey: Keys.destination)
            ?? home.appendingPathComponent("Documents/Desktop Cleaner").path
        sourcePaths = (d.array(forKey: Keys.sources) as? [String])
            ?? [home.appendingPathComponent("Desktop").path]
        grouping = Grouping(rawValue: d.string(forKey: Keys.grouping) ?? "") ?? .month
        frequency = Frequency(rawValue: d.string(forKey: Keys.frequency) ?? "") ?? .daily
        skipLabeled = d.object(forKey: Keys.skipLabeled) as? Bool ?? false
        launchAtLogin = d.object(forKey: Keys.launchAtLogin) as? Bool ?? false
        showNotifications = d.object(forKey: Keys.showNotifications) as? Bool ?? true
        cleaningEnabled = d.object(forKey: Keys.cleaningEnabled) as? Bool ?? true
        lastCleanDate = d.object(forKey: Keys.lastClean) as? Date
    }

    /// Destination as a file URL, expanding a leading `~`.
    var destinationURL: URL {
        URL(fileURLWithPath: (destinationPath as NSString).expandingTildeInPath)
    }

    /// Source folders as file URLs, expanding a leading `~` in each.
    var sourceURLs: [URL] {
        sourcePaths.map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) }
    }
}
