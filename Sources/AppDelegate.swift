import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    private var statusItem: NSStatusItem!
    private let hotkeyManager = HotkeyManager()
    private let displayManager = DisplayManager()
    private let cursorMover = CursorMover()
    private let windowFocusManager = WindowFocusManager()
    private let overlayManager = OverlayFeedbackManager()

    private static let autoFocusKey = "autoFocusTopWindow"
    private var autoFocusItem: NSMenuItem!
    private var shortcutItem: NSMenuItem!
    private var displayMenuItems: [NSMenuItem] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [Self.autoFocusKey: true])
        setupMenuBar()
        refreshDisplays()
        displayManager.startObservingChanges { [weak self] in
            self?.refreshDisplays()
        }
        checkAccessibility()
    }

    private var isAutoFocusEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.autoFocusKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.autoFocusKey) }
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            let symbolNames = ["rectangle.2.swap", "display.2", "arrow.left.arrow.right"]
            var found = false
            for name in symbolNames {
                if let image = NSImage(systemSymbolName: name, accessibilityDescription: "D-Switch") {
                    image.isTemplate = true
                    button.image = image
                    found = true
                    break
                }
            }
            if !found {
                button.title = "D"
            }
        }

        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "D-Switch", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        shortcutItem = NSMenuItem(title: DisplayManager.shortcutSummaryTitle(displayCount: 1), action: nil, keyEquivalent: "")
        shortcutItem.isEnabled = false
        menu.addItem(shortcutItem)

        menu.addItem(NSMenuItem.separator())

        // All nine items exist up front; refreshDisplays() only toggles visibility.
        displayMenuItems = (0..<HotkeyManager.maximumDisplayHotkeys).map { displayIndex in
            let moveItem = NSMenuItem(
                title: "Move Cursor to Display \(displayIndex + 1)",
                action: #selector(moveCursorToDisplayAction(_:)),
                keyEquivalent: ""
            )
            moveItem.target = self
            moveItem.representedObject = displayIndex
            moveItem.isHidden = true
            menu.addItem(moveItem)
            return moveItem
        }

        autoFocusItem = NSMenuItem(title: "Auto-Focus Window", action: #selector(toggleAutoFocus), keyEquivalent: "")
        autoFocusItem.target = self
        autoFocusItem.state = isAutoFocusEnabled ? .on : .off
        menu.addItem(autoFocusItem)

        let refreshItem = NSMenuItem(title: "Refresh Displays", action: #selector(refreshDisplaysAction), keyEquivalent: "")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        // TODO: Launch at Login
        let launchItem = NSMenuItem(title: "Launch at Login", action: nil, keyEquivalent: "")
        launchItem.isEnabled = false
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        menu.delegate = self
        statusItem.menu = menu
    }

    /// Keeps the menu in sync with the current screen list when opened; hotkeys are
    /// only re-registered through refreshDisplays().
    func menuNeedsUpdate(_ menu: NSMenu) {
        let count = DisplayManager.hotkeyDisplayCount(forScreenCount: displayManager.orderedScreens().count)
        guard count > 0 else { return }
        updateDisplayMenuItems(displayCount: count)
    }

    private func updateDisplayMenuItems(displayCount: Int) {
        shortcutItem.title = DisplayManager.shortcutSummaryTitle(displayCount: displayCount)
        for (displayIndex, item) in displayMenuItems.enumerated() {
            item.isHidden = displayIndex >= displayCount
        }
    }

    // MARK: - Display Refresh

    /// Single entry point for launch, automatic change detection, and the manual menu action.
    private func refreshDisplays() {
        let count = DisplayManager.hotkeyDisplayCount(forScreenCount: displayManager.orderedScreens().count)
        guard count > 0 else {
            // Transient empty screen list (wake, clamshell) — keep the previous state.
            NSLog("[D-Switch] Display refresh skipped: no screens reported")
            return
        }
        updateDisplayMenuItems(displayCount: count)
        registerHotkeys(displayCount: count)
        NSLog("[D-Switch] Displays refreshed: \(count) display(s)")
    }

    @objc private func refreshDisplaysAction() {
        displayManager.cancelPendingChange()
        refreshDisplays()
    }

    // MARK: - Hotkey

    private func registerHotkeys(displayCount: Int) {
        hotkeyManager.register(displayCount: displayCount) { [weak self] displayIndex in
            self?.moveCursor(toDisplayAt: displayIndex)
        }
    }

    // MARK: - Cursor Movement

    @objc private func moveCursorToDisplayAction(_ sender: NSMenuItem) {
        guard let displayIndex = sender.representedObject as? Int else { return }
        moveCursor(toDisplayAt: displayIndex)
    }

    private func moveCursor(toDisplayAt displayIndex: Int) {
        let screens = displayManager.orderedScreens()
        guard screens.indices.contains(displayIndex) else {
            NSLog("[D-Switch] Display \(displayIndex + 1) is not connected")
            return
        }
        let target = screens[displayIndex]

        // Keep window activation optional, but always land at the exact screen center.
        if isAutoFocusEnabled {
            _ = windowFocusManager.focusTopWindow(on: target)
        }
        let landingPoint = cursorMover.screenCenter(target)

        cursorMover.warpCursor(to: landingPoint)
        overlayManager.showHint(at: landingPoint, on: target)
    }

    @objc private func toggleAutoFocus() {
        isAutoFocusEnabled.toggle()
        autoFocusItem.state = isAutoFocusEnabled ? .on : .off
    }

    // MARK: - Permissions

    private func checkAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if trusted {
            NSLog("[D-Switch] Accessibility: trusted")
        } else {
            NSLog("[D-Switch] Accessibility: not trusted — opening System Settings. Grant access to enable precise focus-point detection.")
            // Open System Settings → Accessibility pane directly
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    @objc private func quitAction() {
        NSApp.terminate(nil)
    }
}
