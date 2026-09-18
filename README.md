# D-Switch

A small macOS menu-bar utility that moves the mouse cursor directly to a numbered display.

## Usage

- **Option+1** — move to display 1
- **Option+2** — move to display 2
- Continue through **Option+9** for additional displays

Displays use the order provided by macOS (`NSScreen.screens`): the main display is number 1, followed by the remaining displays in system order. Each shortcut moves the cursor to the selected display center, focuses its topmost window when enabled, and shows a brief ring animation.

Connecting or disconnecting a display is detected automatically — the shortcuts and menu update without relaunching D-Switch.

## Build & Run

Requires macOS 14+ and Xcode Command Line Tools (`xcode-select --install`).

```sh
make build   # Compile the .app bundle
make test    # Run hotkey mapping tests
make run     # Build and launch
make clean   # Remove build artifacts
```

The app bundle is created at `build/D-Switch.app`.

## Permissions

Core functionality works without special permissions. For the best experience, grant **Accessibility** permission in **System Settings > Privacy & Security > Accessibility** — this allows D-Switch to focus windows and locate text carets on the target display. D-Switch opens the Accessibility pane once on first launch if permission is missing; afterwards use **Open Accessibility Settings…** in the menu.

## Menu Bar

- **Move Cursor to Display N** — jump directly to the selected display
- **Auto-Focus Window** — toggle automatic window focusing
- **Refresh Displays** — re-scan connected displays and re-register Option+1…N shortcuts (also happens automatically when displays are connected or disconnected)
- **Launch at Login** — register/unregister D-Switch as a login item
- **Accessibility: …** — shows whether Accessibility permission is granted; **Open Accessibility Settings…** jumps to the system pane
- **Quit** — exit D-Switch

## How I Built It

The entire app — every line of Swift, the Makefile, the README — was written by Claude Code (Anthropic's AI coding agent) through conversational prompts. No Xcode project, no SwiftUI, no third-party dependencies. Just `swiftc` compiling raw Swift files into a self-contained `.app` bundle.

The icon was also AI-generated using Nano Banana (Gemini image generation), then converted to `.icns` with `sips` + `iconutil`.

## Technical Details

See [technology.md](technology.md) for implementation details on cursor positioning, gesture detection, display ordering, and architecture.
