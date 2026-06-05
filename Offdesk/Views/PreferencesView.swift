import SwiftUI

/// The preferences window with Status / Settings / Info tabs.
struct PreferencesView: View {
    var body: some View {
        TabView {
            StatusTab()
                .tabItem { Label("Status", systemImage: "switch.2") }
            SettingsTab()
                .tabItem { Label("Settings", systemImage: "gearshape") }
            InfoTab()
                .tabItem { Label("Info", systemImage: "info.circle") }
        }
        .frame(width: 480)
        .padding(.top, 8)
    }
}
