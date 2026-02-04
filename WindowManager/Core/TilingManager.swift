import AppKit

/// Manages automatic window tiling (BSP layout)
class TilingManager {
    
    private var windowManager: WindowManager
    private var settings: WindowManagerSettings
    
    init(windowManager: WindowManager, settings: WindowManagerSettings) {
        self.windowManager = windowManager
        self.settings = settings
    }
    
    func applyTiling() {
        switch settings.tilingMode {
        case .bsp:
            applyBSPTiling()
        case .stack:
            applyStackTiling()
        case .disabled:
            break
        }
    }
    
    private func applyBSPTiling() {
        let windows = windowManager.getAllWindows()
        guard !windows.isEmpty else { return }
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let padding = CGFloat(settings.windowPadding)
        
        // Create BSP tree and tile windows
        let frames = calculateBSPFrames(
            count: windows.count,
            in: CGRect(
                x: screenFrame.minX + padding,
                y: screenFrame.minY + padding,
                width: screenFrame.width - padding * 2,
                height: screenFrame.height - padding * 2
            ),
            gap: padding
        )
        
        for (index, windowInfo) in windows.enumerated() {
            if index < frames.count {
                windowManager.moveAndResize(window: windowInfo.window, to: frames[index], animated: settings.enableAnimations)
            }
        }
    }
    
    private func calculateBSPFrames(count: Int, in rect: CGRect, gap: CGFloat) -> [CGRect] {
        guard count > 0 else { return [] }
        
        if count == 1 {
            return [rect]
        }
        
        // Decide split direction based on aspect ratio
        let splitHorizontally = rect.width > rect.height
        
        let firstHalfCount = count / 2
        let secondHalfCount = count - firstHalfCount
        
        let firstRect: CGRect
        let secondRect: CGRect
        
        if splitHorizontally {
            let halfWidth = (rect.width - gap) / 2
            firstRect = CGRect(
                x: rect.minX,
                y: rect.minY,
                width: halfWidth,
                height: rect.height
            )
            secondRect = CGRect(
                x: rect.minX + halfWidth + gap,
                y: rect.minY,
                width: halfWidth,
                height: rect.height
            )
        } else {
            let halfHeight = (rect.height - gap) / 2
            firstRect = CGRect(
                x: rect.minX,
                y: rect.minY + halfHeight + gap,
                width: rect.width,
                height: halfHeight
            )
            secondRect = CGRect(
                x: rect.minX,
                y: rect.minY,
                width: rect.width,
                height: halfHeight
            )
        }
        
        let firstFrames = calculateBSPFrames(count: firstHalfCount, in: firstRect, gap: gap)
        let secondFrames = calculateBSPFrames(count: secondHalfCount, in: secondRect, gap: gap)
        
        return firstFrames + secondFrames
    }
    
    private func applyStackTiling() {
        let windows = windowManager.getAllWindows()
        guard !windows.isEmpty else { return }
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let padding = CGFloat(settings.windowPadding)
        let stackOffset: CGFloat = 30
        
        let baseWidth = screenFrame.width * 0.7
        let baseHeight = screenFrame.height * 0.8
        let baseX = screenFrame.midX - baseWidth / 2
        let baseY = screenFrame.midY - baseHeight / 2
        
        for (index, windowInfo) in windows.enumerated() {
            let offset = CGFloat(index) * stackOffset
            let frame = CGRect(
                x: baseX + offset,
                y: baseY - offset,
                width: baseWidth,
                height: baseHeight
            )
            windowManager.moveAndResize(window: windowInfo.window, to: frame, animated: settings.enableAnimations)
        }
    }
}
