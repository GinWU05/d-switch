# Technical Details

## Architecture

```
Sources/
  main.swift                   App entry point
  AppDelegate.swift            Menu bar setup, orchestration
  HotkeyManager.swift          Carbon-based per-display global hotkeys
  DisplayManager.swift         Screen enumeration and ordering
  CursorMover.swift            Coordinate math and cursor warping
  WindowFocusManager.swift     Detect + activate topmost window on target display
  OverlayFeedbackManager.swift Visual feedback overlay
```

No third-party dependencies. Uses Carbon Event Manager for global hotkeys, CoreGraphics for cursor movement, and AppKit/QuartzCore for the overlay animation.

## Display Ordering

Display numbers preserve the order supplied by macOS through `NSScreen.screens`. The main display is number 1; remaining displays follow the system order. The list is read again whenever a shortcut is triggered.

## Cursor Positioning & Auto-Focus

D-Switch always places the cursor at the exact center of the selected display. When Auto-Focus Window is enabled, it also activates the topmost window on that display without changing the cursor landing point.

**How it works:**

1. `CGWindowListCopyWindowInfo` finds the topmost normal window (layer 0, ≥50×50pt, >10% overlap) on the target display
2. The owning app is activated via `NSRunningApplication.activate()`
3. The cursor warps to the selected display center

## Visual Feedback

After the cursor moves, a brief ring animation appears at the landing position:

- Accent-colored ring with subtle glow for visibility on any background
- Scale-down and fade animation (~0.75s total)
- Non-interactive floating overlay — doesn't steal focus or block clicks

## Known Limitations

- **Shortcuts are fixed** at Option+1 through Option+9. User customization is not yet implemented.
- **Launch at Login** is listed but not yet wired up. You can add D-Switch to Login Items manually in System Settings.
- If another app registers one of the global shortcuts, D-Switch logs a warning and remains usable via the menu bar for that display.
- The visual hint uses the system accent color. If your accent color has low contrast against your wallpaper, the hint may be less visible.
- Single-display setups support Option+1 and the matching menu action.
