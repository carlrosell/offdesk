import Combine
import Foundation
import Sparkle

/// Owns the Sparkle updater and bridges its state into SwiftUI.
///
/// Sparkle drives auto-updates from the appcast at `SUFeedURL` (see Info.plist),
/// verifying each download against the `SUPublicEDKey` EdDSA public key. The
/// app is not sandboxed, so no installer XPC service is required.
@MainActor
final class UpdaterViewModel: ObservableObject {
    private let updaterController: SPUStandardUpdaterController

    /// Mirrors the updater's readiness so menu items can disable themselves
    /// while a check is already in flight or updates are otherwise unavailable.
    @Published var canCheckForUpdates = false

    init() {
        // `startingUpdater: true` begins the scheduled background checks using
        // the SUEnableAutomaticChecks / SUScheduledCheckInterval Info.plist keys.
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        updaterController.updater
            .publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    /// Shows Sparkle's standard "Checking for updates…" flow.
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
