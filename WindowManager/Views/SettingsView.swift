import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: WindowManagerSettings
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)
            
            WindowSettingsView()
                .tabItem {
                    Label("Windows", systemImage: "macwindow")
                }
                .tag(1)
            
            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
                .tag(2)
            
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
                .tag(3)
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(4)
        }
        .frame(width: 550, height: 450)
        .environmentObject(settings)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @EnvironmentObject var settings: WindowManagerSettings
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                Toggle("Show in Dock", isOn: $settings.showInDock)
            } header: {
                Text("Startup")
            }
            
            Section {
                Toggle("Enable Magnetic Snap", isOn: $settings.enableMagneticSnap)
                    .help("Snap windows to screen edges and corners when dragging")
                
                Toggle("Snap to Other Windows", isOn: $settings.snapToOtherWindows)
                    .disabled(!settings.enableMagneticSnap)
                
                HStack {
                    Text("Edge Snap Threshold")
                    Spacer()
                    Slider(value: Binding(
                        get: { Double(settings.edgeSnapThreshold) },
                        set: { settings.edgeSnapThreshold = Int($0) }
                    ), in: 20...100, step: 10)
                    .frame(width: 150)
                    Text("\(settings.edgeSnapThreshold) px")
                        .frame(width: 50)
                }
            } header: {
                Text("Snapping")
            }
            
            Section {
                Picker("Auto-Tiling Mode", selection: $settings.tilingMode) {
                    ForEach(TilingMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Tiling")
            }
            
            Section {
                Button("Reset to Defaults") {
                    settings.resetToDefaults()
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Window Settings

struct WindowSettingsView: View {
    @EnvironmentObject var settings: WindowManagerSettings
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Window Padding")
                    Spacer()
                    Slider(value: Binding(
                        get: { Double(settings.windowPadding) },
                        set: { settings.windowPadding = Int($0) }
                    ), in: 0...32, step: 2)
                    .frame(width: 150)
                    Text("\(settings.windowPadding) px")
                        .frame(width: 50)
                }
            } header: {
                Text("Layout")
            }
            
            Section {
                Toggle("Enable Animations", isOn: $settings.enableAnimations)
                
                if settings.enableAnimations {
                    HStack {
                        Text("Animation Duration")
                        Spacer()
                        Slider(value: $settings.animationDuration, in: 0.05...0.5, step: 0.05)
                            .frame(width: 150)
                        Text(String(format: "%.2fs", settings.animationDuration))
                            .frame(width: 50)
                    }
                }
            } header: {
                Text("Animations")
            }
            
            Section {
                WindowPaddingPreview(padding: settings.windowPadding)
                    .frame(height: 150)
            } header: {
                Text("Preview")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct WindowPaddingPreview: View {
    let padding: Int
    
    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 400
            let scaledPadding = CGFloat(padding) * scale
            
            ZStack {
                // Screen background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                
                // Two windows side by side
                HStack(spacing: scaledPadding) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.green, lineWidth: 1)
                        )
                }
                .padding(scaledPadding)
            }
        }
    }
}

// MARK: - Shortcuts Settings

struct ShortcutsSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Keyboard Shortcuts")
                    .font(.headline)
                
                ShortcutSection(title: "Half Layouts", shortcuts: [
                    ("Left Half", "⌃⌥←"),
                    ("Right Half", "⌃⌥→"),
                    ("Top Half", "⌃⌥↑"),
                    ("Bottom Half", "⌃⌥↓"),
                ])
                
                ShortcutSection(title: "Third Layouts", shortcuts: [
                    ("Left Third", "⌃⌥D"),
                    ("Center Third", "⌃⌥E"),
                    ("Right Third", "⌃⌥F"),
                    ("Left Two-Thirds", "⌃⌥⇧←"),
                    ("Right Two-Thirds", "⌃⌥⇧→"),
                ])
                
                ShortcutSection(title: "Quarter Layouts", shortcuts: [
                    ("Top-Left", "⌃⌥U"),
                    ("Top-Right", "⌃⌥I"),
                    ("Bottom-Left", "⌃⌥J"),
                    ("Bottom-Right", "⌃⌥K"),
                ])
                
                ShortcutSection(title: "Other", shortcuts: [
                    ("Maximize", "⌃⌥↵"),
                    ("Center", "⌃⌥C"),
                    ("Window Switcher", "⌥Tab"),
                ])
                
                Spacer()
            }
            .padding()
        }
    }
}

struct ShortcutSection: View {
    let title: String
    let shortcuts: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ForEach(shortcuts, id: \.0) { shortcut in
                HStack {
                    Text(shortcut.0)
                    Spacer()
                    Text(shortcut.1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @EnvironmentObject var settings: WindowManagerSettings
    
    let colorOptions = [
        ("accent", "System Accent"),
        ("blue", "Blue"),
        ("green", "Green"),
        ("purple", "Purple"),
        ("orange", "Orange"),
    ]
    
    var body: some View {
        Form {
            Section {
                Picker("Overlay Color", selection: $settings.overlayColor) {
                    ForEach(colorOptions, id: \.0) { option in
                        Text(option.1).tag(option.0)
                    }
                }
                
                HStack {
                    Text("Overlay Opacity")
                    Spacer()
                    Slider(value: $settings.overlayOpacity, in: 0.1...0.5, step: 0.05)
                        .frame(width: 150)
                    Text(String(format: "%.0f%%", settings.overlayOpacity * 100))
                        .frame(width: 50)
                }
            } header: {
                Text("Snap Zone Overlay")
            }
            
            Section {
                OverlayPreview(color: settings.overlayColor, opacity: settings.overlayOpacity)
                    .frame(height: 100)
            } header: {
                Text("Preview")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct OverlayPreview: View {
    let color: String
    let opacity: Double
    
    var overlayColor: Color {
        switch color {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        default: return .accentColor
        }
    }
    
    var body: some View {
        ZStack {
            // Screen background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
            
            // Overlay preview
            RoundedRectangle(cornerRadius: 8)
                .fill(overlayColor.opacity(opacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(overlayColor.opacity(0.6), lineWidth: 2)
                )
                .padding(20)
            
            Text("Snap Zone Preview")
                .foregroundColor(.white)
                .shadow(radius: 2)
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.split.3x3")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("WindowManager")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .foregroundColor(.secondary)
            
            Text("A native macOS window manager with intelligent tiling, magnetic snap zones, and keyboard shortcuts.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Divider()
                .padding(.horizontal, 60)
            
            VStack(spacing: 8) {
                Text("Features")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    FeatureRow(icon: "rectangle.split.2x1", text: "Magnetic Snap Zones")
                    FeatureRow(icon: "keyboard", text: "Keyboard Shortcuts")
                    FeatureRow(icon: "square.grid.3x3", text: "BSP Auto-Tiling")
                    FeatureRow(icon: "macwindow.on.rectangle", text: "Window Switcher")
                    FeatureRow(icon: "display.2", text: "Multi-Monitor Support")
                }
            }
            
            Spacer()
            
            Text("Built with ❤️ using Swift & SwiftUI")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.accentColor)
            Text(text)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(WindowManagerSettings())
}
