# WindowManager

A powerful, free window management app for macOS. Snap windows to screen edges, use keyboard shortcuts for layouts, and switch between windows with an Alt+Tab style switcher. Built with Swift and SwiftUI.

## Features

- 🪟 **Magnetic Snap Zones** - Drag windows to screen edges/corners to snap them into position
- ⌨️ **Keyboard Shortcuts** - Quick layouts with customizable hotkeys
- 🔄 **Window Switcher** - Alt+Tab style window switcher with `⌥Tab`
- 📐 **Multiple Layouts** - Left/Right halves, quarters, thirds, maximize, and center
- 🎯 **Smart Detection** - Automatically detects window dragging for snap zones
- 📍 **Menu Bar** - Quick access to all layouts from the menu bar
- ⚙️ **Customizable** - Configure hotkeys and settings to your preference
- 🚀 **Native & Fast** - Built with SwiftUI for Apple Silicon

## Layouts

| Layout | Default Hotkey | Description |
|--------|---------------|-------------|
| Left Half | `⌃⌥←` | Window fills left 50% |
| Right Half | `⌃⌥→` | Window fills right 50% |
| Top Half | `⌃⌥↑` | Window fills top 50% |
| Bottom Half | `⌃⌥↓` | Window fills bottom 50% |
| Top-Left | `⌃⌥U` | Window fills top-left quarter |
| Top-Right | `⌃⌥I` | Window fills top-right quarter |
| Bottom-Left | `⌃⌥J` | Window fills bottom-left quarter |
| Bottom-Right | `⌃⌥K` | Window fills bottom-right quarter |
| Maximize | `⌃⌥↩` | Window fills entire screen |
| Center | `⌃⌥C` | Window centered at 70% size |
| Left Third | `⌃⌥D` | Window fills left third |
| Center Third | `⌃⌥F` | Window fills center third |
| Right Third | `⌃⌥G` | Window fills right third |

## Window Switcher

Press `⌥Tab` to open the window switcher:
- **Tab / →** - Move to next window
- **⇧Tab / ←** - Move to previous window
- **↑↓** - Navigate grid rows
- **↩** - Select window
- **Esc** - Close switcher
- Release `⌥` - Select current window

## Snap Zones

Drag any window to screen edges or corners to see snap previews:
- **Left/Right Edge** - Snap to half screen
- **Top Edge** - Maximize
- **Corners** - Snap to quarter screen

## Requirements

- macOS 13.0 or later
- Apple Silicon (M1/M2/M3) or Intel Mac
- Accessibility permissions (required for window management)

## Installation

### From DMG (Recommended)

1. Download `WindowManager.dmg` from [Releases](../../releases)
2. Open the DMG file
3. Drag `WindowManager` to your Applications folder
4. Launch from Applications
5. Grant Accessibility permissions when prompted
6. The app will appear in your menu bar

### Build from Source

```bash
# Clone the repository
git clone https://github.com/sahajquinci/WindowManager.git
cd WindowManager

# Make build script executable
chmod +x build.sh

# Build and create DMG
./build.sh
```

## Usage

1. **Launch the App** - Grant Accessibility permissions when prompted
2. **Use Hotkeys** - Press any keyboard shortcut to move the focused window
3. **Drag to Snap** - Drag windows to screen edges/corners
4. **Window Switcher** - Press `⌥Tab` to switch between windows
5. **Menu Bar** - Click the menu bar icon for quick access to layouts

## Permissions

WindowManager requires **Accessibility** permissions to:
- Move and resize windows
- Detect window dragging for snap zones
- Handle global keyboard shortcuts

Go to **System Settings → Privacy & Security → Accessibility** and enable WindowManager.

## Building

### Prerequisites

- Xcode 15.0 or later
- macOS 13.0 SDK or later

### Build Commands

```bash
# Build app
xcodebuild -project WindowManager.xcodeproj \
    -scheme WindowManager \
    -configuration Release \
    -arch arm64 \
    clean build

# Or use the build script
./build.sh
```

## Project Structure

```
WindowManager/
├── WindowManager/
│   ├── AppDelegate.swift       # Main app delegate
│   ├── Core/
│   │   ├── WindowManager.swift # Window manipulation
│   │   ├── HotKeyManager.swift # Keyboard shortcuts
│   │   ├── SnapZoneManager.swift # Snap zone detection
│   │   └── MouseTracker.swift  # Drag detection
│   ├── Models/
│   │   ├── LayoutPreset.swift  # Layout definitions
│   │   └── WindowInfo.swift    # Window data model
│   └── Views/
│       ├── SettingsView.swift  # Settings UI
│       └── WindowSwitcherView.swift # Window switcher
└── WindowManagerTests/
    └── WindowSwitcherSearchTests.swift
```

## Donation

If this app saves you time feel free to show your appreciation using the
following button :D

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/donate?hosted_button_id=W8J2B4E92NEQ2)

## License

Free to use and modify for personal use.

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests.

## Acknowledgments

Inspired by tools like Rectangle, Magnet, and the classic Windows Alt+Tab experience.
