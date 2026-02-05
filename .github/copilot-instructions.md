# WindowManager - Copilot Instructions

## Project Overview
WindowManager is a macOS window management app built with Swift and SwiftUI. It provides:
- Window snapping with drag-to-edge zones
- Keyboard shortcuts for window positioning (halves, quarters, maximize)
- Alt+Tab style window switcher with live window previews
- Menu bar integration

## Key Architecture

### Core Components
- **WindowManager.swift**: Core window management, accessibility API interactions, window enumeration
- **HotKeyManager.swift**: Global keyboard shortcut handling using Carbon APIs
- **SnapZoneManager.swift**: Edge detection and snap zone logic
- **MenuBarController.swift**: Menu bar icon and menu
- **AccessibilityManager.swift**: Accessibility permission handling

### Models
- **WindowModel.swift**: Window data model with thumbnail capture support
- **LayoutPreset.swift**: Window layout definitions
- **WindowManagerSettings.swift**: User preferences

### Views
- **WindowSwitcherView.swift**: Alt+Tab window switcher UI with thumbnail previews
- **SettingsView.swift**: Preferences UI
- **SnapOverlayWindow.swift**: Visual feedback for snap zones

## Required Permissions
The app requires two macOS permissions:
1. **Accessibility** - For window manipulation via AXUIElement APIs
2. **Screen Recording** - For capturing window thumbnails in the switcher

Both are configured in Info.plist with usage descriptions.

## Installation Process
**ALWAYS use install.sh when installing a new version:**
```bash
./install.sh
```

This script:
1. Kills any running instance
2. Resets Accessibility permissions (`tccutil reset Accessibility`)
3. Resets Screen Recording permissions (`tccutil reset ScreenCapture`)
4. Builds the Release configuration
5. Copies to /Applications
6. Launches the app
7. Opens System Preferences to Accessibility settings

**IMPORTANT**: After installing, the user must:
1. Enable WindowManager in System Settings > Privacy & Security > Accessibility
2. Enable WindowManager in System Settings > Privacy & Security > Screen Recording (for window previews)

## Build Commands
```bash
# Quick build
xcodebuild -scheme WindowManager -configuration Release build

# Build with verbose output
xcodebuild -scheme WindowManager -configuration Release build 2>&1

# Clean build
xcodebuild -scheme WindowManager -configuration Release clean build
```

## Common Issues

### Window thumbnails not showing
- Screen Recording permission not granted
- Check Info.plist has `NSScreenCaptureUsageDescription`

### App won't launch after changes
- Code signing issue - rebuild clean
- Or manually sign: `codesign --force --deep --sign - /Applications/WindowManager.app`

### Chrome/multi-process app windows not matching correctly
- Window matching uses bounds (position + size) as primary strategy
- Falls back to title matching if bounds don't match
- Uses `kCGWindowOwnerName` for apps where helper processes own windows

### Window order changes unexpectedly
- If window titles change (like Chrome tabs), use bounds-based matching
- See `getAllWindows()` in WindowManager.swift for matching logic

## Key APIs Used
- **AXUIElement**: Accessibility API for window manipulation
- **CGWindowList**: Window enumeration and thumbnail capture
- **CGWindowListCreateImage**: Capturing window thumbnails (deprecated but functional)
- **Carbon HotKey APIs**: Global keyboard shortcuts

## Code Style
- Swift with SwiftUI for views
- AppKit integration via NSViewRepresentable
- Print statements with emojis for debug logging (🔍, 📝, etc.)

## Testing
```bash
swift run_tests.swift
```
