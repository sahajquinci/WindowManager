import Foundation
import Combine

enum TilingMode: String, CaseIterable, Codable {
    case disabled = "Disabled"
    case bsp = "BSP (Binary Space Partitioning)"
    case stack = "Stack"
}

/// App settings stored in UserDefaults
class WindowManagerSettings: ObservableObject {
    
    private let defaults = UserDefaults.standard
    
    // MARK: - General Settings
    
    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: "launchAtLogin") }
    }
    
    @Published var showInDock: Bool {
        didSet { defaults.set(showInDock, forKey: "showInDock") }
    }
    
    // MARK: - Window Management Settings
    
    @Published var enableMagneticSnap: Bool {
        didSet { defaults.set(enableMagneticSnap, forKey: "enableMagneticSnap") }
    }
    
    @Published var windowPadding: Int {
        didSet { defaults.set(windowPadding, forKey: "windowPadding") }
    }
    
    @Published var enableAnimations: Bool {
        didSet { defaults.set(enableAnimations, forKey: "enableAnimations") }
    }
    
    @Published var animationDuration: Double {
        didSet { defaults.set(animationDuration, forKey: "animationDuration") }
    }
    
    @Published var tilingMode: TilingMode {
        didSet { defaults.set(tilingMode.rawValue, forKey: "tilingMode") }
    }
    
    // MARK: - Snap Zone Settings
    
    @Published var snapToScreenEdges: Bool {
        didSet { defaults.set(snapToScreenEdges, forKey: "snapToScreenEdges") }
    }
    
    @Published var snapToOtherWindows: Bool {
        didSet { defaults.set(snapToOtherWindows, forKey: "snapToOtherWindows") }
    }
    
    @Published var edgeSnapThreshold: Int {
        didSet { defaults.set(edgeSnapThreshold, forKey: "edgeSnapThreshold") }
    }
    
    // MARK: - Appearance Settings
    
    @Published var overlayColor: String {
        didSet { defaults.set(overlayColor, forKey: "overlayColor") }
    }
    
    @Published var overlayOpacity: Double {
        didSet { defaults.set(overlayOpacity, forKey: "overlayOpacity") }
    }
    
    // MARK: - Custom Layouts
    
    @Published var customLayouts: [CustomLayout] {
        didSet {
            if let encoded = try? JSONEncoder().encode(customLayouts) {
                defaults.set(encoded, forKey: "customLayouts")
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load saved values or use defaults
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.showInDock = defaults.object(forKey: "showInDock") as? Bool ?? false
        
        self.enableMagneticSnap = defaults.object(forKey: "enableMagneticSnap") as? Bool ?? true
        self.windowPadding = defaults.object(forKey: "windowPadding") as? Int ?? 8
        self.enableAnimations = defaults.object(forKey: "enableAnimations") as? Bool ?? true
        self.animationDuration = defaults.object(forKey: "animationDuration") as? Double ?? 0.15
        
        if let tilingModeRaw = defaults.string(forKey: "tilingMode"),
           let mode = TilingMode(rawValue: tilingModeRaw) {
            self.tilingMode = mode
        } else {
            self.tilingMode = .disabled
        }
        
        self.snapToScreenEdges = defaults.object(forKey: "snapToScreenEdges") as? Bool ?? true
        self.snapToOtherWindows = defaults.object(forKey: "snapToOtherWindows") as? Bool ?? true
        self.edgeSnapThreshold = defaults.object(forKey: "edgeSnapThreshold") as? Int ?? 50
        
        self.overlayColor = defaults.string(forKey: "overlayColor") ?? "accent"
        self.overlayOpacity = defaults.object(forKey: "overlayOpacity") as? Double ?? 0.2
        
        if let customLayoutsData = defaults.data(forKey: "customLayouts"),
           let layouts = try? JSONDecoder().decode([CustomLayout].self, from: customLayoutsData) {
            self.customLayouts = layouts
        } else {
            self.customLayouts = []
        }
    }
    
    func resetToDefaults() {
        launchAtLogin = false
        showInDock = false
        enableMagneticSnap = true
        windowPadding = 8
        enableAnimations = true
        animationDuration = 0.15
        tilingMode = .disabled
        snapToScreenEdges = true
        snapToOtherWindows = true
        edgeSnapThreshold = 50
        overlayColor = "accent"
        overlayOpacity = 0.2
        customLayouts = []
    }
}
