import AppKit

/// Defines snap zones for window dragging
class SnapZoneManager {
    
    private var settings: WindowManagerSettings
    private var overlayWindow: SnapOverlayWindow?
    
    var currentZone: SnapZone?
    
    init(settings: WindowManagerSettings) {
        self.settings = settings
    }
    
    enum SnapZone: Equatable {
        case leftHalf
        case rightHalf
        case topHalf
        case bottomHalf
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        case leftThird
        case centerThird
        case rightThird
        case maximize
        
        var frame: CGRect {
            guard let screen = NSScreen.main else { return .zero }
            let screenFrame = screen.visibleFrame
            let padding: CGFloat = 8
            
            switch self {
            case .leftHalf:
                return CGRect(
                    x: screenFrame.minX + padding,
                    y: screenFrame.minY + padding,
                    width: (screenFrame.width - padding * 3) / 2,
                    height: screenFrame.height - padding * 2
                )
            case .rightHalf:
                return CGRect(
                    x: screenFrame.midX + padding / 2,
                    y: screenFrame.minY + padding,
                    width: (screenFrame.width - padding * 3) / 2,
                    height: screenFrame.height - padding * 2
                )
            case .topHalf:
                return CGRect(
                    x: screenFrame.minX + padding,
                    y: screenFrame.midY + padding / 2,
                    width: screenFrame.width - padding * 2,
                    height: (screenFrame.height - padding * 3) / 2
                )
            case .bottomHalf:
                return CGRect(
                    x: screenFrame.minX + padding,
                    y: screenFrame.minY + padding,
                    width: screenFrame.width - padding * 2,
                    height: (screenFrame.height - padding * 3) / 2
                )
            case .topLeft:
                return CGRect(
                    x: screenFrame.minX + padding,
                    y: screenFrame.midY + padding / 2,
                    width: (screenFrame.width - padding * 3) / 2,
                    height: (screenFrame.height - padding * 3) / 2
                )
            case .topRight:
                return CGRect(
                    x: screenFrame.midX + padding / 2,
                    y: screenFrame.midY + padding / 2,
                    width: (screenFrame.width - padding * 3) / 2,
                    height: (screenFrame.height - padding * 3) / 2
                )
            case .bottomLeft:
                return CGRect(
                    x: screenFrame.minX + padding,
                    y: screenFrame.minY + padding,
                    width: (screenFrame.width - padding * 3) / 2,
                    height: (screenFrame.height - padding * 3) / 2
                )
            case .bottomRight:
                return CGRect(
                    x: screenFrame.midX + padding / 2,
                    y: screenFrame.minY + padding,
                    width: (screenFrame.width - padding * 3) / 2,
                    height: (screenFrame.height - padding * 3) / 2
                )
            case .leftThird:
                return CGRect(
                    x: screenFrame.minX + padding,
                    y: screenFrame.minY + padding,
                    width: (screenFrame.width - padding * 4) / 3,
                    height: screenFrame.height - padding * 2
                )
            case .centerThird:
                let thirdWidth = (screenFrame.width - padding * 4) / 3
                return CGRect(
                    x: screenFrame.minX + padding * 2 + thirdWidth,
                    y: screenFrame.minY + padding,
                    width: thirdWidth,
                    height: screenFrame.height - padding * 2
                )
            case .rightThird:
                let thirdWidth = (screenFrame.width - padding * 4) / 3
                return CGRect(
                    x: screenFrame.minX + padding * 3 + thirdWidth * 2,
                    y: screenFrame.minY + padding,
                    width: thirdWidth,
                    height: screenFrame.height - padding * 2
                )
            case .maximize:
                return CGRect(
                    x: screenFrame.minX + padding,
                    y: screenFrame.minY + padding,
                    width: screenFrame.width - padding * 2,
                    height: screenFrame.height - padding * 2
                )
            }
        }
    }
    
    func detectZone(at point: CGPoint) -> SnapZone? {
        guard let screen = NSScreen.main else { return nil }
        let screenFrame = screen.frame
        
        let edgeThreshold: CGFloat = 50
        let cornerThreshold: CGFloat = 100
        
        let isNearLeft = point.x < screenFrame.minX + edgeThreshold
        let isNearRight = point.x > screenFrame.maxX - edgeThreshold
        let isNearTop = point.y > screenFrame.maxY - edgeThreshold
        let isNearBottom = point.y < screenFrame.minY + edgeThreshold
        
        let isInLeftCorner = point.x < screenFrame.minX + cornerThreshold
        let isInRightCorner = point.x > screenFrame.maxX - cornerThreshold
        let isInTopCorner = point.y > screenFrame.maxY - cornerThreshold
        let isInBottomCorner = point.y < screenFrame.minY + cornerThreshold
        
        // Corners first (higher priority)
        if isInTopCorner && isInLeftCorner && isNearTop && isNearLeft {
            return .topLeft
        }
        if isInTopCorner && isInRightCorner && isNearTop && isNearRight {
            return .topRight
        }
        // Bottom corners - be more lenient, check corner region AND near edge
        if isInBottomCorner && isInLeftCorner && (isNearBottom || point.y < screenFrame.minY + cornerThreshold) {
            return .bottomLeft
        }
        if isInBottomCorner && isInRightCorner && (isNearBottom || point.y < screenFrame.minY + cornerThreshold) {
            return .bottomRight
        }
        
        // Edges
        if isNearLeft {
            return .leftHalf
        }
        if isNearRight {
            return .rightHalf
        }
        if isNearTop {
            return .maximize
        }
        if isNearBottom {
            return .bottomHalf
        }
        
        return nil
    }
    
    func showOverlay(for zone: SnapZone) {
        if overlayWindow == nil {
            overlayWindow = SnapOverlayWindow()
        }
        
        currentZone = zone
        overlayWindow?.showZone(zone.frame)
    }
    
    func hideOverlay() {
        overlayWindow?.hide()
        currentZone = nil
    }
    
    func getZoneFrame(_ zone: SnapZone) -> CGRect {
        let padding = CGFloat(settings.windowPadding)
        var frame = zone.frame
        
        // Apply custom padding
        frame.origin.x += (padding - 8)
        frame.origin.y += (padding - 8)
        frame.size.width -= (padding - 8) * 2
        frame.size.height -= (padding - 8) * 2
        
        return frame
    }
}
