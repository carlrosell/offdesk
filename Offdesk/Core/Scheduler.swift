import Foundation
import AppKit

/// Fires a repeating action on the main run loop and also re-fires when the Mac
/// wakes from sleep (timers don't fire reliably while asleep). The action decides
/// whether a clean is actually due.
@MainActor
final class Scheduler {
    private let interval: TimeInterval
    private let action: () -> Void
    private var timer: Timer?
    private var wakeObserver: NSObjectProtocol?

    /// The live timer's next fire time — always accurate, even after a wake-from-sleep
    /// re-check (which runs the action but doesn't change the timer's own schedule).
    var nextFireDate: Date? { timer?.fireDate }

    init(interval: TimeInterval, action: @escaping () -> Void) {
        self.interval = interval
        self.action = action
    }

    func start() {
        stop()

        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            // Added to RunLoop.main below, so the timer fires on the main actor.
            MainActor.assumeIsolated { self?.fire() }
        }
        // .common so it keeps firing while menus are being tracked.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            // Delivered on the main queue (queue: .main), so we're on the main actor.
            MainActor.assumeIsolated { self?.fire() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            wakeObserver = nil
        }
    }

    private func fire() {
        action()
    }

    isolated deinit { stop() }
}
