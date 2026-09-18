import Cocoa

final class DisplayManager {

    /// Trailing debounce applied to `NSApplication.didChangeScreenParametersNotification` bursts.
    var changeDebounceInterval: TimeInterval = 0.5

    private var changeObserver: NSObjectProtocol?
    private var pendingChange: DispatchWorkItem?

    deinit {
        stopObservingChanges()
    }

    /// Preserves the display order supplied by macOS (`NSScreen.screens`).
    /// The main display is first; the remaining display numbers follow the system order.
    func orderedScreens() -> [NSScreen] {
        NSScreen.screens
    }

    /// Number of Option+N hotkeys to register for `screenCount` connected displays.
    static func hotkeyDisplayCount(forScreenCount screenCount: Int) -> Int {
        min(max(screenCount, 0), HotkeyManager.maximumDisplayHotkeys)
    }

    /// Title of the disabled menu line summarizing the available Option+N shortcuts.
    static func shortcutSummaryTitle(displayCount: Int) -> String {
        if displayCount <= 1 {
            return "\u{2325}1 select display"
        }
        return "\u{2325}1…\u{2325}\(displayCount) select display"
    }

    // MARK: - Change Observation

    /// Starts observing screen parameter changes; `onChange` runs on the main queue
    /// once per burst of notifications, after `changeDebounceInterval` of quiet.
    func startObservingChanges(_ onChange: @escaping () -> Void) {
        stopObservingChanges()
        changeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleChange(onChange)
        }
    }

    func stopObservingChanges() {
        if let changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
            self.changeObserver = nil
        }
        cancelPendingChange()
    }

    /// Drops any debounced change that has not fired yet.
    func cancelPendingChange() {
        pendingChange?.cancel()
        pendingChange = nil
    }

    private func scheduleChange(_ onChange: @escaping () -> Void) {
        cancelPendingChange()
        let workItem = DispatchWorkItem { [weak self] in
            self?.pendingChange = nil
            onChange()
        }
        pendingChange = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + changeDebounceInterval, execute: workItem)
    }
}
