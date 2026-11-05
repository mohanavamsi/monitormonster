#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$PROJECT_DIR/build/MonitorMonster.app"

if [ ! -d "$APP_DIR" ]; then
    echo "==> App bundle not found, building first..."
    "$PROJECT_DIR/scripts/build.sh"
fi

echo "==> Launching MonitorMonster..."
# Kill any existing instance
pkill -x "MonitorMonster" 2>/dev/null || true

# Launch the app bundle
open "$APP_DIR"
echo "==> MonitorMonster is running in your macOS Menu Bar!"
echo "    Look for the Wi-Fi icon at the top right of your screen."

