import SwiftUI
import AppKit

/// The menu shown when clicking the menu-bar icon, including an
/// "Undo last clean" item.
struct MenuContent: View {
    @EnvironmentObject var controller: CleanController
    @EnvironmentObject var settings: AppSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(lastCleanText)

        Button(controller.isBusy ? "Cleaning…" : "Clean now") {
            controller.cleanNow()
        }
        .disabled(controller.isBusy)

        Button("Open folder with cleaned items") {
            controller.openDestinationFolder()
        }

        Button("Open app") {
            // Open the window first, then (next runloop) activate and bring it
            // forward — for an accessory (LSUIElement) app, activating before the
            // window exists can leave it unfocused or behind other apps.
            openWindow(id: WindowID.preferences)
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                let window = NSApp.windows.first {
                    $0.identifier?.rawValue.contains(WindowID.preferences) == true
                        || $0.title == "Offdesk Preferences"
                }
                window?.makeKeyAndOrderFront(nil)
            }
        }

        Divider()

        Button("Undo last clean") {
            controller.undoLast()
        }
        .disabled(controller.undoRecord == nil || controller.isBusy)

        Divider()

        Button("Quit & Stop cleaning") {
            controller.stopCleaningAndQuit()
        }
        Button("Quit") {
            NSApp.terminate(nil)
        }
    }

    private var lastCleanText: String {
        guard let date = settings.lastCleanDate else { return "Last clean: never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Last clean: " + formatter.localizedString(for: date, relativeTo: Date())
    }
}
