#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/MonitorMonster.app"
CACHE_DIR="/tmp/swift-cache"

echo "==> Building MonitorMonster..."
mkdir -p "$BUILD_DIR"
mkdir -p "$CACHE_DIR"

SWIFT_FILES=$(find "$PROJECT_DIR/Sources/MonitorMonster" -name "*.swift")

swiftc -O \
  -module-cache-path "$CACHE_DIR" \
  -parse-as-library \
  $SWIFT_FILES \
  -o "$BUILD_DIR/MonitorMonster"

echo "==> Creating macOS App Bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/MonitorMonster" "$APP_DIR/Contents/MacOS/MonitorMonster"
chmod +x "$APP_DIR/Contents/MacOS/MonitorMonster"

if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

cat << 'EOF' > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MonitorMonster</string>
    <key>CFBundleIdentifier</key>
    <string>com.monitormonster.mac</string>
    <key>CFBundleName</key>
    <string>MonitorMonster</string>
    <key>CFBundleDisplayName</key>
    <string>MonitorMonster</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleGetInfoString</key>
    <string>MonitorMonster by itvizag</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 itvizag. All rights reserved.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>MonitorMonster uses location permissions to read Wi-Fi network SSID.</string>
</dict>
</plist>
EOF

# Ad-hoc code sign
codesign --force --deep --sign - "$APP_DIR" 2>/dev/null || true

echo "==> Successfully built: $APP_DIR"

