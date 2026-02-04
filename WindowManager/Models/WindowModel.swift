import AppKit

/// Information about a window
struct WindowInfo: Identifiable {
    let id = UUID()
    let window: AXUIElement
    let title: String
    let appName: String
    let appIcon: NSImage?
    let processIdentifier: pid_t
    var orderIndex: Int = Int.max  // For sorting by most recently used
}
