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

# Build a universal binary (arm64 + x86_64) so the app runs on both Apple Silicon
# and Intel Macs. SwiftPM doesn't produce a fat binary natively, so we build each
# arch separately and lipo them together.
echo "==> swift build -c $CONFIG (arm64)"
swift build -c "$CONFIG" --triple arm64-apple-macosx13.0
ARM_BIN="$(swift build -c "$CONFIG" --triple arm64-apple-macosx13.0 --show-bin-path)/AnayasCoPilot"

echo "==> swift build -c $CONFIG (x86_64)"
swift build -c "$CONFIG" --triple x86_64-apple-macosx13.0
X86_BIN="$(swift build -c "$CONFIG" --triple x86_64-apple-macosx13.0 --show-bin-path)/AnayasCoPilot"

for b in "$ARM_BIN" "$X86_BIN"; do
    if [ ! -f "$b" ]; then
        echo "ERROR: missing built binary: $b" >&2
        exit 1
    fi
done

echo "==> assembling .app bundle at $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
lipo -create "$ARM_BIN" "$X86_BIN" -output "$APP_DIR/Contents/MacOS/AnayasCoPilot"
chmod +x "$APP_DIR/Contents/MacOS/AnayasCoPilot"
echo "    archs in fat binary: $(lipo -archs "$APP_DIR/Contents/MacOS/AnayasCoPilot")"

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
    <key>LSMinimumSystemVersion</key><string>13.0</string>
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
