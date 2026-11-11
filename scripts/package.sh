#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/MonitorMonster.app"
DIST_DIR="$PROJECT_DIR/dist"
VERSION="1.0.0"
DMG_NAME="MonitorMonster-${VERSION}.dmg"
ZIP_NAME="MonitorMonster-${VERSION}.zip"

echo "==> 1. Building latest release binary..."
"$PROJECT_DIR/scripts/build.sh"

echo "==> 2. Preparing distribution package in $DIST_DIR..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Stage folder for DMG
STAGING_DIR="/tmp/monitormonster-dmg-staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Copy App to staging
cp -R "$APP_DIR" "$STAGING_DIR/MonitorMonster.app"

# Add custom volume icon if available
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$STAGING_DIR/.VolumeIcon.icns"
    SetFile -c icnC "$STAGING_DIR/.VolumeIcon.icns" 2>/dev/null || true
    SetFile -a C "$STAGING_DIR" 2>/dev/null || true
fi

# Create symlink to /Applications for standard drag-and-drop installer
ln -s /Applications "$STAGING_DIR/Applications"

echo "==> 3. Creating $DMG_NAME (Disk Image Installer)..."
rm -f "$DIST_DIR/$DMG_NAME"
if command -v hdiutil &>/dev/null; then
    hdiutil create -volname "MonitorMonster" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DIST_DIR/$DMG_NAME"
else
    diskutil image create from --format UDZO --volumeName "MonitorMonster" "$STAGING_DIR" "$DIST_DIR/$DMG_NAME"
fi

rm -rf "$STAGING_DIR"

echo "==> 4. Creating $ZIP_NAME (Portable Archive)..."
cd "$BUILD_DIR"
zip -q -r -y "$DIST_DIR/$ZIP_NAME" "MonitorMonster.app"
cd "$PROJECT_DIR"

echo "==> 5. Generating SHA-256 checksums..."
cd "$DIST_DIR"
shasum -a 256 "$DMG_NAME" > "${DMG_NAME}.sha256"
shasum -a 256 "$ZIP_NAME" > "${ZIP_NAME}.sha256"
cd "$PROJECT_DIR"

echo ""
echo "=========================================================="
echo "🎉 MonitorMonster distribution packages ready in dist/:"
echo "   📦 DMG Installer: dist/$DMG_NAME"
echo "   🗜️ ZIP Archive:   dist/$ZIP_NAME"
echo "   🔑 SHA256:        $(cat "$DIST_DIR/${DMG_NAME}.sha256")"
echo "=========================================================="
