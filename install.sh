#!/usr/bin/env bash
set -e

APP_NAME="MonitorMonster"
REPO="mohanavamsi/monitormonster"
INSTALL_DIR="/Applications"

echo "👾 Installing $APP_NAME on your Mac..."

# Check if pre-built DMG is available from release
RELEASE_URL="https://github.com/$REPO/releases/latest/download/MonitorMonster-1.0.0.dmg"
TEMP_DMG="/tmp/${APP_NAME}.dmg"
MOUNT_DIR="/tmp/${APP_NAME}-mount"

if curl -sLf -o "$TEMP_DMG" "$RELEASE_URL" 2>/dev/null; then
    echo "==> Downloading pre-built package..."
    hdiutil attach "$TEMP_DMG" -mountpoint "$MOUNT_DIR" -nobrowse -quiet
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
    cp -R "$MOUNT_DIR/$APP_NAME.app" "$INSTALL_DIR/"
    hdiutil detach "$MOUNT_DIR" -quiet || true
    rm -f "$TEMP_DMG"
else
    echo "==> Building natively from source..."
    TMP_SRC="/tmp/${APP_NAME}-src"
    rm -rf "$TMP_SRC"
    git clone --depth 1 "https://github.com/$REPO.git" "$TMP_SRC"
    cd "$TMP_SRC"
    chmod +x scripts/build.sh
    ./scripts/build.sh
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
    cp -R "build/$APP_NAME.app" "$INSTALL_DIR/"
    rm -rf "$TMP_SRC"
fi

echo "==> Launching $APP_NAME..."
open "$INSTALL_DIR/$APP_NAME.app"

echo ""
echo "🎉 $APP_NAME installed successfully to $INSTALL_DIR/$APP_NAME.app!"
echo "   Look for the glowing monster ball in your top-right Menu Bar!"

