import SwiftUI

struct InfoTab: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.tint)
                .padding(.top, 8)

            Text("Clean checks your source folders every 60 minutes. With daily cleaning it acts once the calendar day changes; with weekly cleaning it acts once 7 or more days have passed since the last clean.")

            Text("You can move everything into a single folder, or group cleaned items by month or by day — sorted into folders named like “2026 June”.")

            Spacer(minLength: 0)

            Text("A modern successor to RINIK Clean.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("Version \(appVersion) (\(buildNumber))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(24)
        .frame(width: 480, height: 280)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
