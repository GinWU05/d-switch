import Cocoa

class DisplayManager {

    /// Preserves the display order supplied by macOS (`NSScreen.screens`).
    /// The main display is first; the remaining display numbers follow the system order.
    func orderedScreens() -> [NSScreen] {
        NSScreen.screens
    }
}
