import SwiftUI
import AppKit

@main
struct OffdeskApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller = CleanController.shared
    @StateObject private var settings = AppSettings.shared

    var body: some Scene {
        MenuBarExtra("Offdesk", image: "MenuBarIcon") {
            MenuContent()
                .environmentObject(controller)
                .environmentObject(settings)
        }
        .menuBarExtraStyle(.menu)

        Window("Offdesk Preferences", id: WindowID.preferences) {
            PreferencesView()
                .environmentObject(controller)
                .environmentObject(settings)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)   // don't pop the window open at launch
    }
}

enum WindowID {
    static let preferences = "preferences"
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        MainActor.assumeIsolated {
            CleanController.shared.start()
        }
    }
}
