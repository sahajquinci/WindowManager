import AppKit
import ApplicationServices

/// Manages accessibility permissions
class AccessibilityManager {
    
    static let shared = AccessibilityManager()
    
    private init() {}
    
    var isAccessibilityEnabled: Bool {
        return AXIsProcessTrusted()
    }
    
    func requestAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
