import Cocoa
import Carbon

class HotkeyManager {

    static let displayKeyCodes: [UInt32] = [
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
    static let maximumDisplayHotkeys = displayKeyCodes.count

    private var hotKeyRefs: [EventHotKeyRef] = []
    private var eventHandlerRef: EventHandlerRef?
    fileprivate var onHotkey: ((Int) -> Void)?

    var registeredHotkeyCount: Int { hotKeyRefs.count }

    static func displayIndex(forHotkeyID id: UInt32) -> Int? {
        guard id >= 1 && id <= UInt32(maximumDisplayHotkeys) else { return nil }
        return Int(id - 1)
    }

    func register(displayCount: Int, callback: @escaping (Int) -> Void) {
        unregister()
        self.onHotkey = callback

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            carbonHotkeyHandler,
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        guard installStatus == noErr else {
            NSLog("[D-Switch] Failed to install Carbon event handler (status: \(installStatus))")
            return
        }

        let registeredCount = min(max(displayCount, 0), Self.maximumDisplayHotkeys)
        for displayIndex in 0..<registeredCount {
            // "DSWT" as FourCharCode: D=0x44 S=0x53 W=0x57 T=0x54
            let hotKeyID = EventHotKeyID(signature: 0x44535754, id: UInt32(displayIndex + 1))
            var hotKeyRef: EventHotKeyRef?
            let registerStatus = RegisterEventHotKey(
                Self.displayKeyCodes[displayIndex],
                UInt32(optionKey),
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )

            if registerStatus != noErr {
                NSLog("[D-Switch] Failed to register hotkey Option+\(displayIndex + 1) (status: \(registerStatus)). The shortcut may conflict with another app.")
            } else if let hotKeyRef {
                hotKeyRefs.append(hotKeyRef)
                NSLog("[D-Switch] Registered global hotkey: Option+\(displayIndex + 1)")
            }
        }
    }

    func unregister() {
        for ref in hotKeyRefs {
            let unregisterStatus = UnregisterEventHotKey(ref)
            if unregisterStatus != noErr {
                NSLog("[D-Switch] Failed to unregister hotkey (status: \(unregisterStatus))")
            }
        }
        hotKeyRefs.removeAll()
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
        onHotkey = nil
    }

    deinit {
        unregister()
    }
}

// C-compatible callback — must not capture context
private func carbonHotkeyHandler(
    _: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData, let event else {
        return OSStatus(eventNotHandledErr)
    }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr,
          let displayIndex = HotkeyManager.displayIndex(forHotkeyID: hotKeyID.id) else {
        return OSStatus(eventNotHandledErr)
    }

    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    DispatchQueue.main.async {
        manager.onHotkey?(displayIndex)
    }
    return noErr
}
