import Carbon
import Cocoa
import Foundation

@main
struct HotkeyConfigurationTests {
    static func main() {
        let expected: [UInt32] = [
            UInt32(kVK_ANSI_1),
            UInt32(kVK_ANSI_2),
            UInt32(kVK_ANSI_3),
            UInt32(kVK_ANSI_4),
            UInt32(kVK_ANSI_5),
            UInt32(kVK_ANSI_6),
            UInt32(kVK_ANSI_7),
            UInt32(kVK_ANSI_8),
            UInt32(kVK_ANSI_9),
        ]

        precondition(HotkeyManager.displayKeyCodes == expected)
        precondition(HotkeyManager.maximumDisplayHotkeys == 9)
        precondition(HotkeyManager.displayIndex(forHotkeyID: 1) == 0)
        precondition(HotkeyManager.displayIndex(forHotkeyID: 3) == 2)
        precondition(HotkeyManager.displayIndex(forHotkeyID: 9) == 8)
        precondition(HotkeyManager.displayIndex(forHotkeyID: 0) == nil)
        precondition(HotkeyManager.displayIndex(forHotkeyID: 10) == nil)

        let macOSDisplayIDs = NSScreen.screens.map(displayID)
        let appDisplayIDs = DisplayManager().orderedScreens().map(displayID)
        precondition(
            appDisplayIDs == macOSDisplayIDs,
            "Display numbering must preserve the order supplied by macOS"
        )

        testHotkeyDisplayCount()
        testShortcutSummaryTitle()
        testHotkeyRegistrationIdempotency()
        testChangeObservationDebounce()

        print("HotkeyConfigurationTests: PASS")
    }

    private static func testHotkeyDisplayCount() {
        precondition(DisplayManager.hotkeyDisplayCount(forScreenCount: 0) == 0)
        precondition(DisplayManager.hotkeyDisplayCount(forScreenCount: 1) == 1)
        precondition(DisplayManager.hotkeyDisplayCount(forScreenCount: 9) == 9)
        precondition(DisplayManager.hotkeyDisplayCount(forScreenCount: 12) == 9)
        precondition(DisplayManager.hotkeyDisplayCount(forScreenCount: -1) == 0)
    }

    private static func testShortcutSummaryTitle() {
        precondition(DisplayManager.shortcutSummaryTitle(displayCount: 1) == "\u{2325}1 select display")
        precondition(DisplayManager.shortcutSummaryTitle(displayCount: 3) == "\u{2325}1…\u{2325}3 select display")
    }

    // Upper bounds only: a running D-Switch instance may already own Option+1..N,
    // which makes RegisterEventHotKey fail without indicating a bug here.
    private static func testHotkeyRegistrationIdempotency() {
        let hotkeyManager = HotkeyManager()
        let ignore: (Int) -> Void = { _ in }

        hotkeyManager.register(displayCount: 1, callback: ignore)
        precondition(hotkeyManager.registeredHotkeyCount <= 1)

        hotkeyManager.register(displayCount: 3, callback: ignore)
        precondition(hotkeyManager.registeredHotkeyCount <= 3)

        hotkeyManager.register(displayCount: 2, callback: ignore)
        precondition(
            hotkeyManager.registeredHotkeyCount <= 2,
            "Re-registering must replace, not accumulate, hotkeys"
        )

        hotkeyManager.register(displayCount: 20, callback: ignore)
        precondition(hotkeyManager.registeredHotkeyCount <= HotkeyManager.maximumDisplayHotkeys)

        hotkeyManager.unregister()
        precondition(hotkeyManager.registeredHotkeyCount == 0)
        hotkeyManager.unregister()
        precondition(hotkeyManager.registeredHotkeyCount == 0)
    }

    private static func testChangeObservationDebounce() {
        let displayManager = DisplayManager()
        displayManager.changeDebounceInterval = 0.1
        var fired = 0
        displayManager.startObservingChanges { fired += 1 }

        for _ in 0..<5 {
            postScreenParametersChange()
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        precondition(fired == 1, "A burst of notifications must collapse into one refresh, got \(fired)")

        postScreenParametersChange()
        displayManager.cancelPendingChange()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        precondition(fired == 1, "cancelPendingChange must drop the scheduled refresh, got \(fired)")

        displayManager.stopObservingChanges()
        postScreenParametersChange()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        precondition(fired == 1, "No refresh may fire after stopObservingChanges, got \(fired)")
    }

    private static func postScreenParametersChange() {
        NotificationCenter.default.post(
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private static func displayID(_ screen: NSScreen) -> CGDirectDisplayID {
        screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
    }
}
