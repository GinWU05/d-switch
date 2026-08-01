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

        print("HotkeyConfigurationTests: PASS")
    }

    private static func displayID(_ screen: NSScreen) -> CGDirectDisplayID {
        screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
    }
}
