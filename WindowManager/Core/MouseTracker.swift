import AppKit

/// Tracks mouse movement for magnetic snap functionality
class MouseTracker {
    
    private var snapZoneManager: SnapZoneManager
    private var windowManager: WindowManager
    private var eventMonitor: Any?
    private var isDragging = false
    private var draggedWindow: AXUIElement?
    private var lastMouseLocation: CGPoint?
    
    init(snapZoneManager: SnapZoneManager, windowManager: WindowManager) {
        self.snapZoneManager = snapZoneManager
        self.windowManager = windowManager
    }
    
    func startTracking() {
        guard eventMonitor == nil else { return }
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp, .leftMouseDragged]) { [weak self] event in
            self?.handleMouseEvent(event)
        }
    }
    
    func stopTracking() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func handleMouseEvent(_ event: NSEvent) {
        let location = NSEvent.mouseLocation
        
        switch event.type {
        case .leftMouseDown:
            handleMouseDown(at: location)
            
        case .leftMouseDragged:
            handleMouseDragged(at: location)
            
        case .leftMouseUp:
            handleMouseUp(at: location)
            
        default:
            break
        }
    }
    
    private func handleMouseDown(at location: CGPoint) {
        // Check if we're starting to drag a window title bar
        if let window = windowManager.getWindowAtPoint(location) {
            // Check if mouse is near the top of the window (title bar area)
            if let windowFrame = windowManager.getWindowFrame(window) {
                let titleBarHeight: CGFloat = 30
                let titleBarRect = CGRect(
                    x: windowFrame.minX,
                    y: windowFrame.maxY - titleBarHeight,
                    width: windowFrame.width,
                    height: titleBarHeight
                )
                
                if titleBarRect.contains(location) {
                    draggedWindow = window
                    lastMouseLocation = location
                }
            }
        }
    }
    
    private func handleMouseDragged(at location: CGPoint) {
        guard draggedWindow != nil else { return }
        
        // Check if we've moved enough to consider this a drag
        if let lastLocation = lastMouseLocation {
            let distance = sqrt(pow(location.x - lastLocation.x, 2) + pow(location.y - lastLocation.y, 2))
            if distance < 5 { return }
        }
        
        isDragging = true
        lastMouseLocation = location
        
        // Detect snap zone
        if let zone = snapZoneManager.detectZone(at: location) {
            if zone != snapZoneManager.currentZone {
                snapZoneManager.showOverlay(for: zone, at: location)
            }
        } else {
            snapZoneManager.hideOverlay()
        }
    }
    
    private func handleMouseUp(at location: CGPoint) {
        defer {
            isDragging = false
            draggedWindow = nil
            lastMouseLocation = nil
            snapZoneManager.hideOverlay()
        }
        
        guard isDragging, let window = draggedWindow else { return }
        
        // If there's an active snap zone, snap the window to it
        if let zone = snapZoneManager.currentZone {
            let targetFrame = snapZoneManager.getZoneFrame(zone)
            windowManager.moveAndResize(window: window, to: targetFrame, animated: true)
        }
    }
    
    deinit {
        stopTracking()
    }
}
