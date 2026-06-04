import SwiftUI
import AppKit

struct SettingsTab: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Folder for cleaned items") {
                HStack {
                    TextField("Destination", text: $settings.destinationPath)
                        .textFieldStyle(.roundedBorder)
                        .labelsHidden()
                    Button {
                        chooseDestination()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .help("Choose a folder")
                }
            }

            Section("Source folders to clean") {
                ForEach(Array(settings.sourcePaths.enumerated()), id: \.offset) { index, path in
                    HStack {
                        Image(systemName: "folder")
                            .foregroundStyle(.secondary)
                        Text((path as NSString).abbreviatingWithTildeInPath)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button(role: .destructive) {
                            removeSource(index)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                        .disabled(settings.sourcePaths.count <= 1)
                    }
                }
                Button {
                    addSource()
                } label: {
                    Label("Add folder…", systemImage: "plus")
                }
            }

            Section {
                Picker("Group items into subfolders", selection: $settings.grouping) {
                    ForEach(Grouping.allCases) { Text($0.label).tag($0) }
                }
                Picker("Clean frequency", selection: $settings.frequency) {
                    ForEach(Frequency.allCases) { Text($0.label).tag($0) }
                }
                Toggle("Skip items with labels", isOn: $settings.skipLabeled)
            }

            Section {
                Toggle("Enable automatic cleaning", isOn: $settings.cleaningEnabled)
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { _, newValue in
                        LoginItemManager.shared.sync(enabled: newValue)
                    }
                Toggle("Show notifications", isOn: $settings.showNotifications)
            }
        }
        .formStyle(.grouped)
    }

    private func chooseDestination() {
        NSApp.activate(ignoringOtherApps: true)   // accessory app must activate to surface the panel
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.directoryURL = settings.destinationURL
        if panel.runModal() == .OK, let url = panel.url {
            settings.destinationPath = url.path
        }
    }

    private func addSource() {
        NSApp.activate(ignoringOtherApps: true)   // accessory app must activate to surface the panel
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Add"
        if panel.runModal() == .OK {
            for url in panel.urls where !settings.sourcePaths.contains(url.path) {
                settings.sourcePaths.append(url.path)
            }
        }
    }

    private func removeSource(_ index: Int) {
        guard settings.sourcePaths.indices.contains(index) else { return }
        settings.sourcePaths.remove(at: index)
    }
}
