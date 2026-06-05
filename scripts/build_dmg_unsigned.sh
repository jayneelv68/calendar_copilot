#!/bin/bash
# Build an UNSIGNED AnayasCoPilot.dmg for testing / sending while signing creds
# are still being set up. Anaya will need to right-click → Open the first time
# (one-time Gatekeeper bypass for unsigned apps). For a no-warning install,
# use scripts/sign_notarize_dmg.sh once a Developer ID cert is in the keychain.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Anaya's Co-Pilot"
APP_DIR="$ROOT/build/${APP_NAME}.app"
DMG_PATH="$ROOT/dist/AnayasCoPilot.dmg"

"$ROOT/scripts/build_app.sh" release >/dev/null

# Ad-hoc sign so the binary at least runs and SMAppService can be inspected.
echo "==> ad-hoc codesign"
codesign --deep --force --sign - "$APP_DIR"

mkdir -p "$ROOT/dist"
rm -f "$DMG_PATH"
STAGING="$ROOT/dist/_dmg_staging"
rm -rf "$STAGING"; mkdir -p "$STAGING"
cp -R "$APP_DIR" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "==> hdiutil create"
hdiutil create -volname "Anaya's Co-Pilot" -srcfolder "$STAGING" \
    -ov -format UDZO "$DMG_PATH" >/dev/null
rm -rf "$STAGING"

echo "DONE: $DMG_PATH ($(du -h "$DMG_PATH" | cut -f1))"
