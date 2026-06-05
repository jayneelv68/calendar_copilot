#!/bin/bash
# Build AnayasCoPilot.app from the SPM executable.
# Usage: scripts/build_app.sh [release|debug]
set -euo pipefail

CONFIG="${1:-release}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Anaya's Co-Pilot"
APP_DIR="$ROOT/build/${APP_NAME}.app"
BUNDLE_ID="com.local.anayacopilot"

cd "$ROOT"

echo "==> swift build -c $CONFIG"
swift build -c "$CONFIG"

BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)/AnayasCoPilot"
if [ ! -f "$BIN_PATH" ]; then
    echo "ERROR: built binary not found at $BIN_PATH" >&2
    exit 1
fi

echo "==> assembling .app bundle at $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/AnayasCoPilot"
chmod +x "$APP_DIR/Contents/MacOS/AnayasCoPilot"

cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
    <key>CFBundleExecutable</key><string>AnayasCoPilot</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSCalendarsUsageDescription</key>
    <string>Anaya's Co-Pilot reads your calendar so a little airplane can fly across the screen ~5 minutes before each meeting.</string>
    <key>NSCalendarsFullAccessUsageDescription</key>
    <string>Anaya's Co-Pilot reads your calendar so a little airplane can fly across the screen ~5 minutes before each meeting.</string>
    <key>NSHumanReadableCopyright</key><string>Made for Anaya, with care.</string>
</dict>
</plist>
EOF

cat > "$APP_DIR/Contents/PkgInfo" <<EOF
APPL????
EOF

echo "==> built: $APP_DIR"
