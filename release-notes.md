## v1.3.0 - Bug Fixes & Improvements

### Bug Fixes
- **Magnetic snap disabled by default** - New installations no longer have magnetic snap enabled, preventing unexpected window movements
- **Multi-monitor snap fix** - Magnetic snap now correctly detects the screen where the cursor is, rather than always using the primary monitor
- **Window switcher responsiveness** - Quick Option+Tab presses now work correctly; switcher closes immediately when Option is released
- **Window order accuracy** - Window switcher now reflects actual macOS window order (most recently used first) instead of custom tracking
- **Removed duplicate permission prompts** - App no longer shows a custom alert before the system accessibility prompt
- **Screen Recording permission prompt** - App now properly triggers the Screen Recording permission request at startup
- **Window switcher appearance fixed** - Resolved issue where window switcher wouldn't appear after recent changes
- **Window switcher sizing** - Panel now correctly sizes to 1200x800 and centers on screen

### Changes
- Simplified window ordering logic using CGWindowList Z-order
- Improved Option key monitoring for window switcher

---

## v1.2.0 - Window Switcher Improvements

### Features
- **Larger window switcher** - Increased to 1200x800 for better visibility
- **Bigger thumbnails** - Window previews now 300x200 for clearer identification
- **Improved window matching** - Better handling of Chrome and multi-process apps

---

## v1.1.0 - Enhanced Window Previews

### Features
- **Live window thumbnails** - Window switcher now shows actual window previews
- **Screen Recording support** - Added permission request for thumbnail capture

---

## v1.0.0 - Initial Release

### Features
- **Magnetic Snap Zones** - Drag windows to screen edges and corners to snap them into position
  - Left/Right halves
  - Top-Left, Top-Right, Bottom-Left, Bottom-Right quarters
  - Maximize on top edge
- **Keyboard Shortcuts** - Full keyboard control for window layouts
  - Halves: `⌃⌥←→↑↓`
  - Quarters: `⌃⌥U/I/J/K`
  - Maximize: `⌃⌥↩`
  - Center: `⌃⌥C`
  - Thirds: `⌃⌥D/F/G`
- **Window Switcher** - Alt+Tab style window switching with `⌥Tab`
  - Grid view of all windows
  - Keyboard navigation with arrows and Tab
  - Release Option to select
- **Menu Bar Integration** - Quick access to all layouts
- **Settings Panel** - Customize hotkeys and preferences

### Known Issues
- Search functionality in window switcher is temporarily disabled
- Bottom corner snap zones may require precise positioning near screen edge

Full Changelog: https://github.com/sahajquinci/WindowManager/commits/v1.0.0
