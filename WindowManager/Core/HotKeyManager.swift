import AppKit
import Carbon

enum HotKeyAction {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case leftThird
    case centerThird
    case rightThird
    case leftTwoThirds
    case rightTwoThirds
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case maximize
    case center
    case showSwitcher
}

/// Manages global keyboard shortcuts
class HotKeyManager {
    
    private var settings: WindowManagerSettings
    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var hotKeyIDs: [UInt32: HotKeyAction] = [:]
    private var nextHotKeyID: UInt32 = 1
    private var handlerRef: UnsafeMutablePointer<HotKeyManager>?
    
    var onHotKey: ((HotKeyAction) -> Void)?
    
    init(settings: WindowManagerSettings) {
        self.settings = settings
        setupEventHandler()
    }
    
    private func setupEventHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        handlerRef = UnsafeMutablePointer<HotKeyManager>.allocate(capacity: 1)
        handlerRef?.initialize(to: self)
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                
                let manager = userData.assumingMemoryBound(to: HotKeyManager.self).pointee
                
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    UInt32(kEventParamDirectObject),
                    UInt32(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                
                if let action = manager.hotKeyIDs[hotKeyID.id] {
                    DispatchQueue.main.async {
                        manager.onHotKey?(action)
                    }
                }
                
                return noErr
            },
            1,
            &eventSpec,
            handlerRef,
            nil
        )
    }
    
    func registerAllHotKeys() {
        // Default hotkey bindings (Control + Option + key)
        let bindings: [(UInt32, UInt32, HotKeyAction)] = [
            // Arrow keys
            (UInt32(kVK_LeftArrow), UInt32(controlKey | optionKey), .leftHalf),
            (UInt32(kVK_RightArrow), UInt32(controlKey | optionKey), .rightHalf),
            (UInt32(kVK_UpArrow), UInt32(controlKey | optionKey), .topHalf),
            (UInt32(kVK_DownArrow), UInt32(controlKey | optionKey), .bottomHalf),
            
            // Third layouts (Control + Option + D/E/F)
            (UInt32(kVK_ANSI_D), UInt32(controlKey | optionKey), .leftThird),
            (UInt32(kVK_ANSI_E), UInt32(controlKey | optionKey), .centerThird),
            (UInt32(kVK_ANSI_F), UInt32(controlKey | optionKey), .rightThird),
            
            // Two-thirds layouts (Control + Option + Shift + Left/Right)
            (UInt32(kVK_LeftArrow), UInt32(controlKey | optionKey | shiftKey), .leftTwoThirds),
            (UInt32(kVK_RightArrow), UInt32(controlKey | optionKey | shiftKey), .rightTwoThirds),
            
            // Corner layouts (Control + Option + U/I/J/K)
            (UInt32(kVK_ANSI_U), UInt32(controlKey | optionKey), .topLeft),
            (UInt32(kVK_ANSI_I), UInt32(controlKey | optionKey), .topRight),
            (UInt32(kVK_ANSI_J), UInt32(controlKey | optionKey), .bottomLeft),
            (UInt32(kVK_ANSI_K), UInt32(controlKey | optionKey), .bottomRight),
            
            // Maximize and Center
            (UInt32(kVK_Return), UInt32(controlKey | optionKey), .maximize),
            (UInt32(kVK_ANSI_C), UInt32(controlKey | optionKey), .center),
            
            // Window Switcher (Option + Tab)
            (UInt32(kVK_Tab), UInt32(optionKey), .showSwitcher),
        ]
        
        for (keyCode, modifiers, action) in bindings {
            registerHotKey(keyCode: keyCode, modifiers: modifiers, action: action)
        }
    }
    
    private func registerHotKey(keyCode: UInt32, modifiers: UInt32, action: HotKeyAction) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x574D4752), id: nextHotKeyID) // "WMGR"
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            hotKeyRefs.append(hotKeyRef)
            hotKeyIDs[nextHotKeyID] = action
            nextHotKeyID += 1
        }
    }
    
    func unregisterAllHotKeys() {
        for hotKeyRef in hotKeyRefs {
            if let ref = hotKeyRef {
                UnregisterEventHotKey(ref)
            }
        }
        hotKeyRefs.removeAll()
        hotKeyIDs.removeAll()
        nextHotKeyID = 1
    }
    
    deinit {
        unregisterAllHotKeys()
        handlerRef?.deinitialize(count: 1)
        handlerRef?.deallocate()
    }
}
