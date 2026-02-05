import AppKit
import CoreGraphics

/// Information about a window
struct WindowInfo: Identifiable {
    let id = UUID()
    let window: AXUIElement
    let title: String
    let appName: String
    let appIcon: NSImage?
    let processIdentifier: pid_t
    var orderIndex: Int = Int.max  // For sorting by most recently used
    var thumbnail: NSImage?  // Window preview thumbnail
    var windowID: CGWindowID = 0  // For capturing thumbnails
    var bounds: CGRect = .zero  // Window position/size for stable identification
}

// MARK: - Window Thumbnail Capture

extension WindowInfo {
    /// Capture a thumbnail of this window
    static func captureThumbnail(windowID: CGWindowID, maxSize: CGSize = CGSize(width: 600, height: 400)) -> NSImage? {
        // Capture the window image
        guard let cgImage = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowID,
            [.boundsIgnoreFraming, .bestResolution]
        ) else {
            return nil
        }
        
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        // Calculate scaled size maintaining aspect ratio
        let scale = min(maxSize.width / imageSize.width, maxSize.height / imageSize.height)
        let scaledSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        // Create NSImage from CGImage
        let nsImage = NSImage(cgImage: cgImage, size: scaledSize)
        return nsImage
    }
}
