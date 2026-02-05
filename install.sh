#!/bin/bash

# WindowManager Install Script
# This script builds and installs the app to /Applications

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUNDLE_ID="com.windowmanager.app"

echo "🔨 Building WindowManager (Release)..."
cd "$SCRIPT_DIR"

# Kill any running instance
pkill -f "WindowManager$" 2>/dev/null || true
sleep 0.3

# Reset permissions for this app (so user just needs to toggle, not re-add)
echo "🔐 Resetting accessibility permissions..."
tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null || true

echo "🔐 Resetting screen recording permissions..."
tccutil reset ScreenCapture "$BUNDLE_ID" 2>/dev/null || true

# Build release version
xcodebuild -scheme WindowManager -configuration Release build -quiet

# Find the built app
BUILD_DIR=$(xcodebuild -scheme WindowManager -configuration Release -showBuildSettings 2>/dev/null | grep -m 1 "BUILT_PRODUCTS_DIR" | awk '{print $3}')
APP_PATH="$BUILD_DIR/WindowManager.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Build failed - app not found at $APP_PATH"
    exit 1
fi

echo "📦 Installing to /Applications..."
rm -rf /Applications/WindowManager.app 2>/dev/null || true
cp -R "$APP_PATH" /Applications/

echo "🚀 Launching WindowManager..."
open /Applications/WindowManager.app

# Open privacy settings
sleep 1
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

echo ""
echo "✅ WindowManager installed!"
echo ""
echo "👉 Enable WindowManager in the settings windows:"
echo "   1. Privacy & Security > Accessibility (required)"
echo "   2. Privacy & Security > Screen Recording (for window previews)"
echo ""
echo "💡 Tip: Open Screen Recording settings with:"
echo "   open 'x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture'"
echo ""
