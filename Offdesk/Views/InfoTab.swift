import SwiftUI

struct InfoTab: View {
    @EnvironmentObject var updater: UpdaterViewModel

    var body: some View {
        VStack(spacing: 14) {
            Text("Offdesk checks your source folders every 60 minutes. With daily cleaning it acts once the calendar day changes; with weekly cleaning it acts once 7 or more days have passed since the last clean.")

            Text("You can move everything into a single folder, or group cleaned items by month or by day — sorted into folders named like “2026 June”.")

            Spacer(minLength: 0)

            Button("Check for Updates…") {
                updater.checkForUpdates()
            }
            .disabled(!updater.canCheckForUpdates)

            Text("Version \(appVersion) (\(buildNumber))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 280, maxHeight: .infinity, alignment: .top)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
