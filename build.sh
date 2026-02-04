#!/bin/bash

# Build script for WindowManager
# This script builds the app and creates a DMG installer

set -e

echo "🔨 Building WindowManager..."

# Clean build folder
rm -rf build/

# Build the app for Release
xcodebuild -project WindowManager.xcodeproj \
    -scheme WindowManager \
    -configuration Release \
    -derivedDataPath build \
    -arch arm64 \
    clean build

echo "✅ Build complete!"

# Create DMG
echo "📦 Creating DMG..."

APP_PATH="build/Build/Products/Release/WindowManager.app"
DMG_PATH="WindowManager.dmg"

# Remove old DMG if exists
rm -f "$DMG_PATH"

# Create temporary DMG folder
TMP_DMG_DIR="build/dmg_temp"
rm -rf "$TMP_DMG_DIR"
mkdir -p "$TMP_DMG_DIR"

# Copy app to temp folder
cp -R "$APP_PATH" "$TMP_DMG_DIR/"

# Create Applications symlink
ln -s /Applications "$TMP_DMG_DIR/Applications"

# Create DMG
hdiutil create -volname "WindowManager" \
    -srcfolder "$TMP_DMG_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

# Clean up
rm -rf "$TMP_DMG_DIR"

echo "✅ DMG created: $DMG_PATH"
echo ""
echo "📱 Installation:"
echo "1. Open WindowManager.dmg"
echo "2. Drag WindowManager to Applications folder"
echo "3. Launch from Applications"
echo "4. Grant Accessibility permissions when prompted"
echo ""
echo "⌨️  Keyboard shortcuts:"
echo "   ⌥Tab - Window switcher"
echo "   ⌃⌥← → ↑ ↓ - Snap to halves"
echo "   ⌃⌥U I J K - Snap to quarters"
echo "   ⌃⌥↩ - Maximize"
