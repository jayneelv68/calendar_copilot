#!/bin/bash
# Sign, notarize, staple, and package AnayasCoPilot.app into AnayasCoPilot.dmg.
# Requirements:
#   - "Developer ID Application" cert in keychain
#   - notarytool keychain profile named "notary-profile":
#       xcrun notarytool store-credentials notary-profile \
#         --apple-id "<your-apple-id>" --team-id "<TEAMID>" \
#         --password "<app-specific-password>"
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Anaya's Co-Pilot"
APP_DIR="$ROOT/build/${APP_NAME}.app"
DMG_PATH="$ROOT/dist/AnayasCoPilot.dmg"
ENT="$ROOT/scripts/entitlements.plist"
PROFILE="notary-profile"
TEAM_ID="XVD66LAV3K"

if [ ! -d "$APP_DIR" ]; then
    echo "ERROR: $APP_DIR not found; run scripts/build_app.sh first." >&2
    exit 1
fi

IDENTITY=$(security find-identity -v -p codesigning | awk -F'"' '/Developer ID Application/{print $2; exit}')
if [ -z "${IDENTITY:-}" ]; then
    echo "ERROR: no 'Developer ID Application' identity in keychain." >&2
    exit 1
fi

echo "==> codesign with: $IDENTITY"
codesign --deep --force --options runtime --timestamp \
    --entitlements "$ENT" \
    --sign "$IDENTITY" "$APP_DIR"
codesign --verify --verbose "$APP_DIR"

mkdir -p "$ROOT/dist"
echo "==> building dmg at $DMG_PATH"
rm -f "$DMG_PATH"
STAGING="$ROOT/dist/_dmg_staging"
rm -rf "$STAGING"; mkdir -p "$STAGING"
cp -R "$APP_DIR" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "Anaya's Co-Pilot" -srcfolder "$STAGING" \
    -ov -format UDZO "$DMG_PATH"
rm -rf "$STAGING"

echo "==> codesign dmg"
codesign --force --sign "$IDENTITY" --timestamp "$DMG_PATH"

echo "==> notarize dmg (waiting)…"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$PROFILE" --wait

echo "==> staple"
xcrun stapler staple "$APP_DIR"
xcrun stapler staple "$DMG_PATH"

echo "==> verify"
spctl -a -vv "$APP_DIR"
xcrun stapler validate "$DMG_PATH"

echo "DONE: $DMG_PATH"
