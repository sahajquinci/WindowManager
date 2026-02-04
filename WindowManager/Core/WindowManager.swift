import AppKit
import ApplicationServices

/// Core window management using macOS Accessibility API
class WindowManager {
    
    // MARK: - Accessibility Check
    
    var isAccessibilityEnabled: Bool {
        return AXIsProcessTrusted()
    }
    
    // MARK: - Get Focused Window
    
    func getFocusedWindow() -> AXUIElement? {
        guard isAccessibilityEnabled else { return nil }
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        
        var focusedWindow: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        
        guard result == .success else { return nil }
        return (focusedWindow as! AXUIElement)
    }
    
    // MARK: - Get All Windows
    
    func getAllWindows() -> [WindowInfo] {
        var windowInfos: [WindowInfo] = []
        
        // Use CGWindowList to get windows in front-to-back order (most recent first)
        // Include all windows, not just on-screen ones, to catch hidden/minimized apps
        let options = CGWindowListOption(arrayLiteral: .optionAll, .excludeDesktopElements)
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        
        // Build a map of window order by PID and window name
        var windowOrder: [(pid: pid_t, name: String, index: Int)] = []
        for (index, windowInfo) in windowList.enumerated() {
            if let pid = windowInfo[kCGWindowOwnerPID as String] as? pid_t,
               let layer = windowInfo[kCGWindowLayer as String] as? Int,
               layer == 0 { // Normal window layer
                let name = windowInfo[kCGWindowName as String] as? String ?? ""
                windowOrder.append((pid: pid, name: name, index: index))
            }
        }
        
        let runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular
        }
        
        for app in runningApps {
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            
            var windowsRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
            
            guard result == .success, let windows = windowsRef as? [AXUIElement] else { continue }
            
            for window in windows {
                // Get window title
                var titleRef: CFTypeRef?
                AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
                let title = titleRef as? String ?? ""
                
                // Check if minimized - we'll include them but mark them
                var minimizedRef: CFTypeRef?
                AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedRef)
                let isMinimized = minimizedRef as? Bool ?? false
                
                // Check if window has a valid role (skip things like menubars, popovers)
                var roleRef: CFTypeRef?
                AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &roleRef)
                let role = roleRef as? String ?? ""
                
                // Only include actual windows (AXWindow role)
                if role != "AXWindow" && !role.isEmpty { continue }
                
                // Use app name for untitled windows
                var displayTitle = title.isEmpty ? (app.localizedName ?? "Untitled") : title
                
                // Mark minimized windows
                if isMinimized {
                    displayTitle = "🔻 " + displayTitle
                }
                
                // Find the order index for this window
                let orderIndex = windowOrder.firstIndex(where: { 
                    $0.pid == app.processIdentifier && ($0.name == title || $0.name == displayTitle.replacingOccurrences(of: "🔻 ", with: ""))
                }).map { windowOrder[$0].index } ?? Int.max
                
                let info = WindowInfo(
                    window: window,
                    title: displayTitle,
                    appName: app.localizedName ?? "Unknown",
                    appIcon: app.icon,
                    processIdentifier: app.processIdentifier,
                    orderIndex: orderIndex
                )
                windowInfos.append(info)
            }
        }
        
        // Sort by order index (most recently focused first)
        // Windows not in CGWindowList (hidden/minimized) will be at the end
        windowInfos.sort { $0.orderIndex < $1.orderIndex }
        
        return windowInfos
    }
    
    // MARK: - Get Windows for App
    
    func getWindowsForApp(_ bundleIdentifier: String) -> [WindowInfo] {
        guard let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == bundleIdentifier
        }) else { return [] }
        
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        
        guard result == .success, let windows = windowsRef as? [AXUIElement] else { return [] }
        
        return windows.compactMap { window -> WindowInfo? in
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
            let title = titleRef as? String ?? ""
            
            if title.isEmpty { return nil }
            
            return WindowInfo(
                window: window,
                title: title,
                appName: app.localizedName ?? "Unknown",
                appIcon: app.icon,
                processIdentifier: app.processIdentifier
            )
        }
    }
    
    // MARK: - Window Manipulation
    
    func moveAndResize(window: AXUIElement, to frame: CGRect, animated: Bool = true) {
        if animated {
            // Get current frame for animation
            let currentFrame = getWindowFrame(window)
            
            // Animate the transition
            animateWindowTransition(window: window, from: currentFrame, to: frame)
        } else {
            setWindowFrame(window, frame: frame)
        }
    }
    
    private func setWindowFrame(_ window: AXUIElement, frame: CGRect) {
        // Convert from bottom-left origin (Cocoa) to top-left origin (Accessibility API)
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let adjustedY = screenHeight - frame.maxY
        
        var position = CGPoint(x: frame.origin.x, y: adjustedY)
        var size = CGSize(width: frame.width, height: frame.height)
        
        if let positionValue = AXValueCreate(.cgPoint, &position) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        }
        
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
    }
    
    private func animateWindowTransition(window: AXUIElement, from: CGRect?, to: CGRect) {
        guard let from = from else {
            setWindowFrame(window, frame: to)
            return
        }
        
        let duration: TimeInterval = 0.15
        let steps = 10
        let stepDuration = duration / Double(steps)
        
        for step in 0...steps {
            let progress = CGFloat(step) / CGFloat(steps)
            let eased = easeOutCubic(progress)
            
            let currentX = from.origin.x + (to.origin.x - from.origin.x) * eased
            let currentY = from.origin.y + (to.origin.y - from.origin.y) * eased
            let currentWidth = from.width + (to.width - from.width) * eased
            let currentHeight = from.height + (to.height - from.height) * eased
            
            let currentFrame = CGRect(x: currentX, y: currentY, width: currentWidth, height: currentHeight)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                self.setWindowFrame(window, frame: currentFrame)
            }
        }
    }
    
    private func easeOutCubic(_ t: CGFloat) -> CGFloat {
        return 1 - pow(1 - t, 3)
    }
    
    func getWindowFrame(_ window: AXUIElement) -> CGRect? {
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
        
        guard let positionValue = positionRef,
              let sizeValue = sizeRef else { return nil }
        
        var position = CGPoint.zero
        var size = CGSize.zero
        
        AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        
        // Convert from top-left origin to bottom-left origin
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let adjustedY = screenHeight - position.y - size.height
        
        return CGRect(x: position.x, y: adjustedY, width: size.width, height: size.height)
    }
    
    func getWindowSize(_ window: AXUIElement) -> CGSize? {
        var sizeRef: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
        
        guard let sizeValue = sizeRef else { return nil }
        
        var size = CGSize.zero
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        
        return size
    }
    
    func focusWindow(_ windowInfo: WindowInfo) {
        // Check if window is minimized and unminimize it first
        var minimizedRef: CFTypeRef?
        AXUIElementCopyAttributeValue(windowInfo.window, kAXMinimizedAttribute as CFString, &minimizedRef)
        let isMinimized = minimizedRef as? Bool ?? false
        
        if isMinimized {
            // Unminimize the window
            AXUIElementSetAttributeValue(windowInfo.window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        }
        
        // Activate the application (this also unhides hidden apps)
        if let app = NSRunningApplication(processIdentifier: windowInfo.processIdentifier) {
            app.activate(options: [.activateIgnoringOtherApps])
        }
        
        // Raise the specific window and make it main
        AXUIElementSetAttributeValue(windowInfo.window, kAXMainAttribute as CFString, kCFBooleanTrue)
        AXUIElementPerformAction(windowInfo.window, kAXRaiseAction as CFString)
    }
    
    func minimizeWindow(_ window: AXUIElement) {
        AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
    }
    
    func closeWindow(_ window: AXUIElement) {
        var closeButton: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXCloseButtonAttribute as CFString, &closeButton)
        
        if let button = closeButton {
            AXUIElementPerformAction(button as! AXUIElement, kAXPressAction as CFString)
        }
    }
    
    // MARK: - Window at Point
    
    func getWindowAtPoint(_ point: CGPoint) -> AXUIElement? {
        var element: AXUIElement?
        
        let systemWide = AXUIElementCreateSystemWide()
        var elementRef: CFTypeRef?
        
        // Convert point to screen coordinates (Accessibility uses top-left origin)
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let adjustedPoint = CGPoint(x: point.x, y: screenHeight - point.y)
        
        let result = AXUIElementCopyElementAtPosition(systemWide, Float(adjustedPoint.x), Float(adjustedPoint.y), &element)
        
        if result == .success, let elem = element {
            // Walk up to find the window
            return findWindowAncestor(elem)
        }
        
        return nil
    }
    
    private func findWindowAncestor(_ element: AXUIElement) -> AXUIElement? {
        var current: AXUIElement? = element
        
        while let elem = current {
            var roleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(elem, kAXRoleAttribute as CFString, &roleRef)
            
            if let role = roleRef as? String, role == kAXWindowRole as String {
                return elem
            }
            
            var parentRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(elem, kAXParentAttribute as CFString, &parentRef)
            
            if result != .success {
                break
            }
            
            current = parentRef as! AXUIElement?
        }
        
        return nil
    }
}
