import Cocoa

class CursorMover {

    /// Warps the cursor to the given CG point and posts a mouse-moved event.
    func warpCursor(to point: CGPoint) {
        CGWarpMouseCursorPosition(point)
        if let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                               mouseCursorPosition: point, mouseButton: .left) {
            event.post(tap: .cghidEventTap)
        }
    }

    /// Returns the center of a screen in CG coordinates (top-left origin).
    func screenCenter(_ screen: NSScreen) -> CGPoint {
        nsToCG(NSPoint(x: screen.frame.midX, y: screen.frame.midY))
    }

    /// Converts a point from NS coordinates (bottom-left origin) to CG coordinates (top-left origin).
    func nsToCG(_ nsPoint: NSPoint) -> CGPoint {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        return CGPoint(x: nsPoint.x, y: primaryHeight - nsPoint.y)
    }
}
