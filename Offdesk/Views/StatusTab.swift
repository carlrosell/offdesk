import SwiftUI

struct StatusTab: View {
    @EnvironmentObject var controller: CleanController
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                LabeledContent("Last clean", value: lastCleanString)
                LabeledContent("Items moved last run", value: "\(controller.lastResult?.itemCount ?? 0)")
                LabeledContent("Next check", value: nextCheckString)
                LabeledContent("Automatic cleaning", value: settings.cleaningEnabled ? "On" : "Off")
            }

            Section {
                Button {
                    controller.cleanNow()
                } label: {
                    Label(controller.isBusy ? "Cleaning…" : "Clean now", systemImage: "sparkles")
                }
                .disabled(controller.isBusy)

                Button {
                    controller.undoLast()
                } label: {
                    Label("Undo last clean", systemImage: "arrow.uturn.backward")
                }
                .disabled(controller.undoRecord == nil || controller.isBusy)
            }
        }
        .formStyle(.grouped)
    }

    private var lastCleanString: String {
        guard let date = settings.lastCleanDate else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var nextCheckString: String {
        guard settings.cleaningEnabled, let date = controller.nextCheck else { return "—" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
