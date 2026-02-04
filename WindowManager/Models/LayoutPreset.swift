import Foundation

/// Preset layout configurations
enum LayoutPreset: String, CaseIterable, Codable {
    case leftHalf = "Left Half"
    case rightHalf = "Right Half"
    case topHalf = "Top Half"
    case bottomHalf = "Bottom Half"
    case leftThird = "Left Third"
    case centerThird = "Center Third"
    case rightThird = "Right Third"
    case leftTwoThirds = "Left Two-Thirds"
    case rightTwoThirds = "Right Two-Thirds"
    case topLeft = "Top-Left Quarter"
    case topRight = "Top-Right Quarter"
    case bottomLeft = "Bottom-Left Quarter"
    case bottomRight = "Bottom-Right Quarter"
    case maximize = "Maximize"
    case center = "Center"
    
    var iconName: String {
        switch self {
        case .leftHalf: return "rectangle.lefthalf.filled"
        case .rightHalf: return "rectangle.righthalf.filled"
        case .topHalf: return "rectangle.tophalf.filled"
        case .bottomHalf: return "rectangle.bottomhalf.filled"
        case .leftThird: return "rectangle.split.3x1"
        case .centerThird: return "rectangle.center.inset.filled"
        case .rightThird: return "rectangle.split.3x1"
        case .leftTwoThirds: return "rectangle.leadinghalf.inset.filled"
        case .rightTwoThirds: return "rectangle.trailinghalf.inset.filled"
        case .topLeft: return "rectangle.inset.topleft.filled"
        case .topRight: return "rectangle.inset.topright.filled"
        case .bottomLeft: return "rectangle.inset.bottomleft.filled"
        case .bottomRight: return "rectangle.inset.bottomright.filled"
        case .maximize: return "rectangle.fill"
        case .center: return "rectangle.center.inset.filled"
        }
    }
}

/// Custom layout that user can define
struct CustomLayout: Codable, Identifiable {
    let id: UUID
    var name: String
    var xRatio: Double
    var yRatio: Double
    var widthRatio: Double
    var heightRatio: Double
    
    init(name: String, xRatio: Double, yRatio: Double, widthRatio: Double, heightRatio: Double) {
        self.id = UUID()
        self.name = name
        self.xRatio = xRatio
        self.yRatio = yRatio
        self.widthRatio = widthRatio
        self.heightRatio = heightRatio
    }
}
