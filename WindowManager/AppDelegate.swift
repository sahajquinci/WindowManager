import AppKit
import SwiftUI
import Combine
import ObjectiveC

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var settingsWindow: NSWindow?
    var windowSwitcherPanel: NSPanel?
    
    let settingsManager = WindowManagerSettings()
    var windowManager: WindowManager!
    var hotKeyManager: HotKeyManager!
    var snapZoneManager: SnapZoneManager!
    var tilingManager: TilingManager!
    var mouseTracker: MouseTracker!
    var menuBarController: MenuBarController!
    
    private var cancellables = Set<AnyCancellable>()
    
    // Track window usage order (most recently used first)
    // Stores process ID and window title as a unique identifier
    private var mruWindowOrder: [(pid: pid_t, title: String)] = []
    
    // For Option+Tab quick switching
    private var optionKeyMonitor: Any?
    private var currentSwitcherState: WindowSwitcherState?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize core components
        windowManager = WindowManager()
        hotKeyManager = HotKeyManager(settings: settingsManager)
        snapZoneManager = SnapZoneManager(settings: settingsManager)
        tilingManager = TilingManager(windowManager: windowManager, settings: settingsManager)
        mouseTracker = MouseTracker(snapZoneManager: snapZoneManager, windowManager: windowManager)
        menuBarController = MenuBarController(appDelegate: self)
        
        // Setup menu bar
        setupMenuBar()
        
        // Check accessibility permissions
        checkAccessibilityPermissions()
        
        // Register hotkeys
        setupHotKeys()
        
        // Start mouse tracking for snap zones
        if settingsManager.enableMagneticSnap {
            mouseTracker.startTracking()
        }
        
        // Observe settings changes
        observeSettingsChanges()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "rectangle.split.3x3", accessibilityDescription: "Window Manager")
            button.image?.size = NSSize(width: 18, height: 18)
        }
        
        let menu = NSMenu()
        
        // Quick layout options
        let layoutItem = NSMenuItem(title: "Quick Layouts", action: nil, keyEquivalent: "")
        let layoutSubmenu = NSMenu()
        
        layoutSubmenu.addItem(NSMenuItem(title: "Left Half", action: #selector(layoutLeftHalf), keyEquivalent: ""))
        layoutSubmenu.addItem(NSMenuItem(title: "Right Half", action: #selector(layoutRightHalf), keyEquivalent: ""))
        layoutSubmenu.addItem(NSMenuItem(title: "Top Half", action: #selector(layoutTopHalf), keyEquivalent: ""))
        layoutSubmenu.addItem(NSMenuItem(title: "Bottom Half", action: #selector(layoutBottomHalf), keyEquivalent: ""))
        layoutSubmenu.addItem(NSMenuItem.separator())
        layoutSubmenu.addItem(NSMenuItem(title: "Left Third", action: #selector(layoutLeftThird), keyEquivalent: ""))
        layoutSubmenu.addItem(NSMenuItem(title: "Center Third", action: #selector(layoutCenterThird), keyEquivalent: ""))
        layoutSubmenu.addItem(NSMenuItem(title: "Right Third", action: #selector(layoutRightThird), keyEquivalent: ""))
        layoutSubmenu.addItem(NSMenuItem(title: "Left Two-Thirds", action: #selector(layoutLeftTwoThirds), keyEquivalent: ""))
        layoutSubmenu.addItem(NSMenuItem(title: "Right Two-Thirds", action: #selector(layoutRightTwoThirds), keyEquivalent: ""))
        layoutSubmenu.addItem(NSMenuItem.separator())
        layoutSubmenu.addItem(NSMenuItem(title: "Top-Left Quarter", action: #selector(layoutTopLeft), keyEquivalent: ""))
        layoutSubmenu.addItem(NSMenuItem(title: "Top-Right Quarter", action: #selector(layoutTopRight), keyEquivalent: ""))
        layoutSubmenu.addItem(NSMenuItem(title: "Bottom-Left Quarter", action: #selector(layoutBottomLeft), keyEquivalent: ""))
        layoutSubmenu.addItem(NSMenuItem(title: "Bottom-Right Quarter", action: #selector(layoutBottomRight), keyEquivalent: ""))
        layoutSubmenu.addItem(NSMenuItem.separator())
        layoutSubmenu.addItem(NSMenuItem(title: "Maximize", action: #selector(layoutMaximize), keyEquivalent: ""))
        layoutSubmenu.addItem(NSMenuItem(title: "Center", action: #selector(layoutCenter), keyEquivalent: ""))
        
        for item in layoutSubmenu.items {
            item.target = self
        }
        
        layoutItem.submenu = layoutSubmenu
        menu.addItem(layoutItem)
        
        // Tiling Mode
        let tilingItem = NSMenuItem(title: "Auto-Tiling Mode", action: nil, keyEquivalent: "")
        let tilingSubmenu = NSMenu()
        
        let bspItem = NSMenuItem(title: "BSP Layout", action: #selector(setBSPTiling), keyEquivalent: "")
        bspItem.target = self
        tilingSubmenu.addItem(bspItem)
        
        let stackItem = NSMenuItem(title: "Stack Layout", action: #selector(setStackTiling), keyEquivalent: "")
        stackItem.target = self
        tilingSubmenu.addItem(stackItem)
        
        let disableItem = NSMenuItem(title: "Disable Auto-Tiling", action: #selector(disableTiling), keyEquivalent: "")
        disableItem.target = self
        tilingSubmenu.addItem(disableItem)
        
        tilingItem.submenu = tilingSubmenu
        menu.addItem(tilingItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Window Switcher
        let switcherItem = NSMenuItem(title: "Window Switcher", action: #selector(showWindowSwitcher), keyEquivalent: "Tab")
        switcherItem.keyEquivalentModifierMask = [.option]
        switcherItem.target = self
        menu.addItem(switcherItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Magnetic Snap toggle
        let snapItem = NSMenuItem(title: "Magnetic Snap", action: #selector(toggleMagneticSnap), keyEquivalent: "")
        snapItem.target = self
        snapItem.state = settingsManager.enableMagneticSnap ? .on : .off
        menu.addItem(snapItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit WindowManager", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessibilityEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAccessibilityAlert()
            }
        }
    }
    
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Access Required"
        alert.informativeText = "WindowManager needs accessibility access to manage your windows. Please grant access in System Settings > Privacy & Security > Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
    
    private func setupHotKeys() {
        hotKeyManager.onHotKey = { [weak self] action in
            self?.handleHotKeyAction(action)
        }
        hotKeyManager.registerAllHotKeys()
    }
    
    private func observeSettingsChanges() {
        settingsManager.$enableMagneticSnap
            .sink { [weak self] enabled in
                if enabled {
                    self?.mouseTracker.startTracking()
                } else {
                    self?.mouseTracker.stopTracking()
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleHotKeyAction(_ action: HotKeyAction) {
        guard let window = windowManager.getFocusedWindow() else { return }
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let padding = CGFloat(settingsManager.windowPadding)
        
        let targetFrame: CGRect
        
        switch action {
        case .leftHalf:
            targetFrame = CGRect(
                x: screenFrame.minX + padding,
                y: screenFrame.minY + padding,
                width: (screenFrame.width - padding * 3) / 2,
                height: screenFrame.height - padding * 2
            )
        case .rightHalf:
            targetFrame = CGRect(
                x: screenFrame.midX + padding / 2,
                y: screenFrame.minY + padding,
                width: (screenFrame.width - padding * 3) / 2,
                height: screenFrame.height - padding * 2
            )
        case .topHalf:
            targetFrame = CGRect(
                x: screenFrame.minX + padding,
                y: screenFrame.midY + padding / 2,
                width: screenFrame.width - padding * 2,
                height: (screenFrame.height - padding * 3) / 2
            )
        case .bottomHalf:
            targetFrame = CGRect(
                x: screenFrame.minX + padding,
                y: screenFrame.minY + padding,
                width: screenFrame.width - padding * 2,
                height: (screenFrame.height - padding * 3) / 2
            )
        case .leftThird:
            targetFrame = CGRect(
                x: screenFrame.minX + padding,
                y: screenFrame.minY + padding,
                width: (screenFrame.width - padding * 4) / 3,
                height: screenFrame.height - padding * 2
            )
        case .centerThird:
            let thirdWidth = (screenFrame.width - padding * 4) / 3
            targetFrame = CGRect(
                x: screenFrame.minX + padding * 2 + thirdWidth,
                y: screenFrame.minY + padding,
                width: thirdWidth,
                height: screenFrame.height - padding * 2
            )
        case .rightThird:
            let thirdWidth = (screenFrame.width - padding * 4) / 3
            targetFrame = CGRect(
                x: screenFrame.minX + padding * 3 + thirdWidth * 2,
                y: screenFrame.minY + padding,
                width: thirdWidth,
                height: screenFrame.height - padding * 2
            )
        case .leftTwoThirds:
            targetFrame = CGRect(
                x: screenFrame.minX + padding,
                y: screenFrame.minY + padding,
                width: (screenFrame.width - padding * 3) * 2 / 3,
                height: screenFrame.height - padding * 2
            )
        case .rightTwoThirds:
            let twoThirdsWidth = (screenFrame.width - padding * 3) * 2 / 3
            targetFrame = CGRect(
                x: screenFrame.maxX - padding - twoThirdsWidth,
                y: screenFrame.minY + padding,
                width: twoThirdsWidth,
                height: screenFrame.height - padding * 2
            )
        case .topLeft:
            targetFrame = CGRect(
                x: screenFrame.minX + padding,
                y: screenFrame.midY + padding / 2,
                width: (screenFrame.width - padding * 3) / 2,
                height: (screenFrame.height - padding * 3) / 2
            )
        case .topRight:
            targetFrame = CGRect(
                x: screenFrame.midX + padding / 2,
                y: screenFrame.midY + padding / 2,
                width: (screenFrame.width - padding * 3) / 2,
                height: (screenFrame.height - padding * 3) / 2
            )
        case .bottomLeft:
            targetFrame = CGRect(
                x: screenFrame.minX + padding,
                y: screenFrame.minY + padding,
                width: (screenFrame.width - padding * 3) / 2,
                height: (screenFrame.height - padding * 3) / 2
            )
        case .bottomRight:
            targetFrame = CGRect(
                x: screenFrame.midX + padding / 2,
                y: screenFrame.minY + padding,
                width: (screenFrame.width - padding * 3) / 2,
                height: (screenFrame.height - padding * 3) / 2
            )
        case .maximize:
            targetFrame = CGRect(
                x: screenFrame.minX + padding,
                y: screenFrame.minY + padding,
                width: screenFrame.width - padding * 2,
                height: screenFrame.height - padding * 2
            )
        case .center:
            let windowSize = windowManager.getWindowSize(window) ?? CGSize(width: 800, height: 600)
            targetFrame = CGRect(
                x: screenFrame.midX - windowSize.width / 2,
                y: screenFrame.midY - windowSize.height / 2,
                width: windowSize.width,
                height: windowSize.height
            )
        case .showSwitcher:
            showWindowSwitcher()
            return
        }
        
        windowManager.moveAndResize(window: window, to: targetFrame, animated: settingsManager.enableAnimations)
    }
    
    // MARK: - Menu Actions
    
    @objc func layoutLeftHalf() { handleHotKeyAction(.leftHalf) }
    @objc func layoutRightHalf() { handleHotKeyAction(.rightHalf) }
    @objc func layoutTopHalf() { handleHotKeyAction(.topHalf) }
    @objc func layoutBottomHalf() { handleHotKeyAction(.bottomHalf) }
    @objc func layoutLeftThird() { handleHotKeyAction(.leftThird) }
    @objc func layoutCenterThird() { handleHotKeyAction(.centerThird) }
    @objc func layoutRightThird() { handleHotKeyAction(.rightThird) }
    @objc func layoutLeftTwoThirds() { handleHotKeyAction(.leftTwoThirds) }
    @objc func layoutRightTwoThirds() { handleHotKeyAction(.rightTwoThirds) }
    @objc func layoutTopLeft() { handleHotKeyAction(.topLeft) }
    @objc func layoutTopRight() { handleHotKeyAction(.topRight) }
    @objc func layoutBottomLeft() { handleHotKeyAction(.bottomLeft) }
    @objc func layoutBottomRight() { handleHotKeyAction(.bottomRight) }
    @objc func layoutMaximize() { handleHotKeyAction(.maximize) }
    @objc func layoutCenter() { handleHotKeyAction(.center) }
    
    @objc func setBSPTiling() {
        settingsManager.tilingMode = .bsp
        tilingManager.applyTiling()
    }
    
    @objc func setStackTiling() {
        settingsManager.tilingMode = .stack
        tilingManager.applyTiling()
    }
    
    @objc func disableTiling() {
        settingsManager.tilingMode = .disabled
    }
    
    @objc func toggleMagneticSnap() {
        settingsManager.enableMagneticSnap.toggle()
        
        // Update menu item state
        if let menu = statusItem?.menu,
           let item = menu.items.first(where: { $0.title == "Magnetic Snap" }) {
            item.state = settingsManager.enableMagneticSnap ? .on : .off
        }
    }
    
    @objc func showWindowSwitcher() {
        // If panel exists and Option+Tab pressed again, cycle to next window
        if let panel = windowSwitcherPanel, let state = currentSwitcherState {
            state.moveRight()
            return
        }
        
        // Check accessibility first
        if !AXIsProcessTrusted() {
            showAccessibilityAlert()
            return
        }
        
        var windows = windowManager.getAllWindows()
        
        // Sort windows by MRU order
        windows.sort { window1, window2 in
            let key1 = (pid: window1.processIdentifier, title: window1.title)
            let key2 = (pid: window2.processIdentifier, title: window2.title)
            
            let index1 = mruWindowOrder.firstIndex { $0.pid == key1.pid && $0.title == key1.title } ?? Int.max
            let index2 = mruWindowOrder.firstIndex { $0.pid == key2.pid && $0.title == key2.title } ?? Int.max
            
            return index1 < index2
        }
        
        // Create state object to track selection
        let state = WindowSwitcherState(windows: windows, onSelect: { [weak self] window in
            self?.updateMRUOrder(window: window)
            self?.windowManager.focusWindow(window)
            self?.closeWindowSwitcher()
        }, onDismiss: { [weak self] in
            self?.closeWindowSwitcher()
        })
        
        // Start with second item selected (first is current window)
        if windows.count > 1 {
            state.selectedIndex = 1
        }
        
        currentSwitcherState = state
        
        let contentView = WindowSwitcherView(state: state)
        let hostingView = NSHostingView(rootView: contentView)
        
        // Use a regular panel that can become key
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.contentView = hostingView
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let panelFrame = panel.frame
            let x = screenFrame.midX - panelFrame.width / 2
            let y = screenFrame.midY - panelFrame.height / 2
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        windowSwitcherPanel = panel
        panel.switcherState = state
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        
        // Monitor for Option key release to select current window
        startOptionKeyMonitor()
    }
    
    private func startOptionKeyMonitor() {
        stopOptionKeyMonitor()
        
        // Use both local and global monitors to catch the Option key release
        optionKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            // Check if Option key was released
            if !event.modifierFlags.contains(.option) {
                // Option released - select current window and close
                DispatchQueue.main.async {
                    self?.selectCurrentAndClose()
                }
            }
        }
        
        // Also add local monitor for when our app is active
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            if !event.modifierFlags.contains(.option) {
                DispatchQueue.main.async {
                    self?.selectCurrentAndClose()
                }
            }
            return event
        }
        
        // Store local monitor reference (we'll clean it up with the global one)
        objc_setAssociatedObject(self, "localOptionMonitor", localMonitor, .OBJC_ASSOCIATION_RETAIN)
    }
    
    private func stopOptionKeyMonitor() {
        if let monitor = optionKeyMonitor {
            NSEvent.removeMonitor(monitor)
            optionKeyMonitor = nil
        }
        
        // Also remove local monitor
        if let localMonitor = objc_getAssociatedObject(self, "localOptionMonitor") {
            NSEvent.removeMonitor(localMonitor)
            objc_setAssociatedObject(self, "localOptionMonitor", nil, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    private func selectCurrentAndClose() {
        if let state = currentSwitcherState {
            state.selectCurrent()
        }
        closeWindowSwitcher()
    }
    
    // Custom panel class that can become key
    class KeyablePanel: NSPanel {
        weak var switcherState: WindowSwitcherState?
        
        override var canBecomeKey: Bool { true }
        override var canBecomeMain: Bool { true }
        
        override func keyDown(with event: NSEvent) {
            guard let state = switcherState else {
                super.keyDown(with: event)
                return
            }
            
            switch event.keyCode {
            case 126: // Up arrow
                state.moveUp()
            case 125: // Down arrow
                state.moveDown()
            case 123: // Left arrow
                state.moveLeft()
            case 124: // Right arrow
                state.moveRight()
            case 36: // Return/Enter
                state.selectCurrent()
            case 53: // Escape
                state.onDismiss()
            case 48: // Tab
                if event.modifierFlags.contains(.shift) {
                    state.moveLeft()
                } else {
                    state.moveRight()
                }
            default:
                super.keyDown(with: event)
            }
        }
    }
    
    func closeWindowSwitcher() {
        stopOptionKeyMonitor()
        currentSwitcherState = nil
        windowSwitcherPanel?.close()
        windowSwitcherPanel = nil
    }
    
    private func updateMRUOrder(window: WindowInfo) {
        let key = (pid: window.processIdentifier, title: window.title)
        
        // Remove if already exists
        mruWindowOrder.removeAll { $0.pid == key.pid && $0.title == key.title }
        
        // Insert at the front
        mruWindowOrder.insert(key, at: 0)
        
        // Keep list reasonable size
        if mruWindowOrder.count > 50 {
            mruWindowOrder = Array(mruWindowOrder.prefix(50))
        }
    }
    
    @objc func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        
        if settingsWindow == nil {
            let settingsView = SettingsView()
                .environmentObject(settingsManager)
            
            let hostingController = NSHostingController(rootView: settingsView)
            
            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.title = "WindowManager Settings"
            settingsWindow?.setContentSize(NSSize(width: 550, height: 500))
            settingsWindow?.styleMask = [.titled, .closable, .miniaturizable]
            settingsWindow?.center()
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        mouseTracker.stopTracking()
        hotKeyManager.unregisterAllHotKeys()
    }
}
