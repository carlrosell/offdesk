import Foundation
import SwiftUI
import AppKit

/// Coordinates settings, scheduling, the clean engine, history and notifications.
/// All UI-facing state lives here and is mutated on the main actor; the actual
/// file I/O runs on a background queue.
@MainActor
final class CleanController: ObservableObject {
    static let shared = CleanController()

    let settings = AppSettings.shared

    /// Result of the most recent run (may have moved 0 items) — for status display.
    @Published var lastResult: CleanRecord?
    /// The most recent run that actually moved items — what "Undo last clean" reverses.
    @Published var undoRecord: CleanRecord?
    @Published var isBusy = false
    @Published var nextCheck: Date?

    private var scheduler: Scheduler?

    private init() {
        let stored = CleanHistoryStore.shared.load()
        undoRecord = stored
        lastResult = stored
    }

    /// Called once at launch (from the app delegate).
    func start() {
        Notifier.shared.requestAuthorizationIfNeeded()
        LoginItemManager.shared.sync(enabled: settings.launchAtLogin)
        startScheduler()
        checkAndCleanIfDue()
    }

    private func startScheduler() {
        scheduler?.stop()
        let scheduler = Scheduler(interval: 60 * 60) {
            // The timer fires on the main run loop, so we're safely on the main actor.
            MainActor.assumeIsolated {
                CleanController.shared.checkAndCleanIfDue()
            }
        }
        scheduler.start()
        self.scheduler = scheduler
        nextCheck = scheduler.nextFireDate
    }

    /// Runs a clean only if the schedule says one is due.
    func checkAndCleanIfDue() {
        nextCheck = scheduler?.nextFireDate
        guard settings.cleaningEnabled else { return }
        if settings.frequency.shouldClean(lastClean: settings.lastCleanDate, now: Date()) {
            cleanNow()
        }
    }

    /// Cleans immediately, regardless of schedule.
    func cleanNow() {
        guard !isBusy else { return }
        isBusy = true

        let engine = CleanEngine(
            sources: settings.sourceURLs,
            destination: settings.destinationURL,
            grouping: settings.grouping,
            skipLabeled: settings.skipLabeled
        )
        let now = Date()

        DispatchQueue.global(qos: .utility).async {
            let result = engine.run(now: now)
            let record = CleanRecord(
                date: now,
                destination: engine.destination.path,
                moves: result.moves,
                skippedCount: result.skipped,
                errorCount: result.errors.count
            )
            for error in result.errors { NSLog("Offdesk: %@", error) }
            DispatchQueue.main.async {
                // The block runs on the main queue, so we're safely on the main actor.
                MainActor.assumeIsolated {
                    self.finishClean(record: record, now: now)
                }
            }
        }
    }

    private func finishClean(record: CleanRecord, now: Date) {
        settings.lastCleanDate = now
        lastResult = record
        if !record.moves.isEmpty {
            CleanHistoryStore.shared.save(record)
            undoRecord = record
        }
        nextCheck = scheduler?.nextFireDate
        isBusy = false

        if settings.showNotifications {
            Notifier.shared.notifyCleaned(count: record.moves.count, destination: record.destination)
        }
    }

    /// Moves the items from the last clean back to their original locations.
    func undoLast() {
        guard !isBusy, let record = undoRecord else { return }
        isBusy = true

        DispatchQueue.global(qos: .utility).async {
            let fm = FileManager.default
            var unrestored: [FileMove] = []     // moves we couldn't reverse — keep so undo can retry
            var emptiedDirs: Set<String> = []   // dated subfolders we may now be able to prune

            for move in record.moves {
                let from = URL(fileURLWithPath: move.from)   // original location
                let to = URL(fileURLWithPath: move.to)        // where it now lives
                // If the item is no longer where we left it, there's nothing to restore.
                guard fm.fileExists(atPath: to.path) else { continue }
                let originalDir = from.deletingLastPathComponent()
                do {
                    try fm.createDirectory(at: originalDir, withIntermediateDirectories: true)
                    // uniqueDestination keeps the original name when free and only
                    // suffixes (" 2") if a *different* file now occupies it — never clobbers.
                    let restoreURL = CleanEngine.uniqueDestination(
                        for: from.lastPathComponent, in: originalDir, fileManager: fm
                    )
                    try fm.moveItem(at: to, to: restoreURL)
                    emptiedDirs.insert(to.deletingLastPathComponent().path)
                } catch {
                    NSLog("Offdesk: undo failed for %@: %@", to.lastPathComponent, error.localizedDescription)
                    unrestored.append(move)
                }
            }

            // Remove dated subfolders we just emptied (but never the destination root),
            // and only when truly empty.
            for dir in emptiedDirs where dir != record.destination && dir.hasPrefix(record.destination + "/") {
                if let contents = try? fm.contentsOfDirectory(atPath: dir), contents.isEmpty {
                    try? fm.removeItem(atPath: dir)
                }
            }

            let finalUnrestored = unrestored
            DispatchQueue.main.async {
                // The block runs on the main queue, so we're safely on the main actor.
                MainActor.assumeIsolated {
                    if finalUnrestored.isEmpty {
                        CleanHistoryStore.shared.clear()
                        self.undoRecord = nil
                    } else {
                        // Some items couldn't be moved back — keep a record of just those
                        // so the user can retry "Undo last clean".
                        var retry = record
                        retry.moves = finalUnrestored
                        CleanHistoryStore.shared.save(retry)
                        self.undoRecord = retry
                    }
                    self.isBusy = false
                }
            }
        }
    }

    /// Disables automatic cleaning and the login item, then quits — the menu's
    /// "Quit & Stop cleaning". A plain "Quit" leaves these intact so cleaning
    /// resumes at next login.
    func stopCleaningAndQuit() {
        settings.cleaningEnabled = false
        settings.launchAtLogin = false
        LoginItemManager.shared.sync(enabled: false)
        scheduler?.stop()
        NSApp.terminate(nil)
    }

    func openDestinationFolder() {
        let url = settings.destinationURL
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.open(url)
    }
}
