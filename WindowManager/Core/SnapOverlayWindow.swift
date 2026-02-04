import AppKit

/// Overlay window that shows snap zone preview
class SnapOverlayWindow: NSWindow {
    
    private var overlayView: SnapOverlayView!
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        overlayView = SnapOverlayView()
        self.contentView = overlayView
    }
    
    func showZone(_ frame: CGRect) {
        self.setFrame(frame, display: true)
        overlayView.animate(show: true)
        self.orderFront(nil)
    }
    
    func hide() {
        overlayView.animate(show: false) { [weak self] in
            self?.orderOut(nil)
        }
    }
}

class SnapOverlayView: NSView {
    
    private var isVisible = false
    private var animationProgress: CGFloat = 0
    private var displayLink: CVDisplayLink?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.cornerRadius = 12
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let context = NSGraphicsContext.current?.cgContext
        
        // Background with blur effect simulation
        let backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.15 * animationProgress)
        backgroundColor.setFill()
        
        let backgroundPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 4), xRadius: 12, yRadius: 12)
        backgroundPath.fill()
        
        // Border
        let borderColor = NSColor.controlAccentColor.withAlphaComponent(0.6 * animationProgress)
        borderColor.setStroke()
        
        let borderPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 4), xRadius: 12, yRadius: 12)
        borderPath.lineWidth = 2
        borderPath.stroke()
    }
    
    func animate(show: Bool, completion: (() -> Void)? = nil) {
        isVisible = show
        let targetProgress: CGFloat = show ? 1.0 : 0.0
        let duration: TimeInterval = 0.15
        let startProgress = animationProgress
        let startTime = CACurrentMediaTime()
        
        Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let elapsed = CACurrentMediaTime() - startTime
            let progress = min(elapsed / duration, 1.0)
            let eased = self.easeOutCubic(CGFloat(progress))
            
            self.animationProgress = startProgress + (targetProgress - startProgress) * eased
            self.needsDisplay = true
            
            if progress >= 1.0 {
                timer.invalidate()
                completion?()
            }
        }
    }
    
    private func easeOutCubic(_ t: CGFloat) -> CGFloat {
        return 1 - pow(1 - t, 3)
    }
}
