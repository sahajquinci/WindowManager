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
        
        // Build a map of window order and IDs by PID, owner name, bounds
        struct CGWindowInfo {
            let pid: pid_t
            let ownerName: String
            let name: String
            let index: Int
            let windowID: CGWindowID
            let bounds: CGRect
            var used: Bool
        }
        
        var cgWindows: [CGWindowInfo] = []
        for (index, windowInfo) in windowList.enumerated() {
            if let pid = windowInfo[kCGWindowOwnerPID as String] as? pid_t,
               let layer = windowInfo[kCGWindowLayer as String] as? Int,
               let windowID = windowInfo[kCGWindowNumber as String] as? CGWindowID,
               layer == 0 { // Normal window layer
                let name = windowInfo[kCGWindowName as String] as? String ?? ""
                let ownerName = windowInfo[kCGWindowOwnerName as String] as? String ?? ""
                
                // Get window bounds
                var bounds = CGRect.zero
                if let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: Any],
                   let x = boundsDict["X"] as? CGFloat,
                   let y = boundsDict["Y"] as? CGFloat,
                   let width = boundsDict["Width"] as? CGFloat,
                   let height = boundsDict["Height"] as? CGFloat {
                    bounds = CGRect(x: x, y: y, width: width, height: height)
                }
                
                cgWindows.append(CGWindowInfo(
                    pid: pid, ownerName: ownerName, name: name,
                    index: index, windowID: windowID, bounds: bounds, used: false
                ))
            }
        }
        
        let runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular
        }
        
        for app in runningApps {
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            let appName = app.localizedName ?? ""
            
            var windowsRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
            
            guard result == .success, let windows = windowsRef as? [AXUIElement] else { continue }
            
            for window in windows {
                // Get window title
                var titleRef: CFTypeRef?
                AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
                let title = titleRef as? String ?? ""
                
                // Get window position and size for matching
                var positionRef: CFTypeRef?
                var sizeRef: CFTypeRef?
                AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
                AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
                
                var axBounds = CGRect.zero
                if let positionValue = positionRef {
                    var point = CGPoint.zero
                    AXValueGetValue(positionValue as! AXValue, .cgPoint, &point)
                    axBounds.origin = point
                }
                if let sizeValue = sizeRef {
                    var size = CGSize.zero
                    AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
                    axBounds.size = size
                }
                
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
                var displayTitle = title.isEmpty ? appName : title
                
                // Mark minimized windows
                if isMinimized {
                    displayTitle = "🔻 " + displayTitle
                }
                
                // Helper to check if bounds match (within tolerance for rounding)
                func boundsMatch(_ a: CGRect, _ b: CGRect) -> Bool {
                    let tolerance: CGFloat = 5
                    return abs(a.origin.x - b.origin.x) < tolerance &&
                           abs(a.origin.y - b.origin.y) < tolerance &&
                           abs(a.width - b.width) < tolerance &&
                           abs(a.height - b.height) < tolerance
                }
                
                // Find matching CG window - prioritize by bounds matching
                var matchIndex: Int? = nil
                
                // Strategy 1: Match by bounds + PID (most reliable)
                if matchIndex == nil && axBounds.width > 0 {
                    matchIndex = cgWindows.firstIndex(where: {
                        !$0.used && $0.pid == app.processIdentifier && boundsMatch($0.bounds, axBounds)
                    })
                }
                
                // Strategy 2: Match by bounds + owner name (for multi-process apps)
                if matchIndex == nil && axBounds.width > 0 {
                    matchIndex = cgWindows.firstIndex(where: {
                        !$0.used && $0.ownerName == appName && boundsMatch($0.bounds, axBounds)
                    })
                }
                
                // Strategy 3: Exact title match by PID
                if matchIndex == nil {
                    matchIndex = cgWindows.firstIndex(where: {
                        !$0.used && $0.pid == app.processIdentifier && $0.name == title && !title.isEmpty
                    })
                }
                
                // Strategy 4: Exact title match by owner name
                if matchIndex == nil {
                    matchIndex = cgWindows.firstIndex(where: {
                        !$0.used && $0.ownerName == appName && $0.name == title && !title.isEmpty
                    })
                }
                
                // Strategy 5: Any unused window for this PID
                if matchIndex == nil {
                    matchIndex = cgWindows.firstIndex(where: {
                        !$0.used && $0.pid == app.processIdentifier
                    })
                }
                
                // Strategy 6: Any unused window for this owner name
                if matchIndex == nil {
                    matchIndex = cgWindows.firstIndex(where: {
                        !$0.used && $0.ownerName == appName
                    })
                }
                
                var orderIndex = Int.max
                var windowID: CGWindowID = 0
                
                if let idx = matchIndex {
                    orderIndex = cgWindows[idx].index
                    windowID = cgWindows[idx].windowID
                    cgWindows[idx].used = true  // Mark as used
                }
                
                // Capture thumbnail for the window (requires Screen Recording permission)
                var thumbnail: NSImage? = nil
                if windowID > 0 {
                    thumbnail = WindowInfo.captureThumbnail(windowID: windowID)
                }
                
                var info = WindowInfo(
                    window: window,
                    title: displayTitle,
                    appName: appName.isEmpty ? "Unknown" : appName,
                    appIcon: app.icon,
                    processIdentifier: app.processIdentifier,
                    orderIndex: orderIndex
                )
                info.thumbnail = thumbnail
                info.windowID = windowID
                info.bounds = axBounds
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
