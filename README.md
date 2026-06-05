# Anaya's Co-Pilot

A tiny SwiftUI menu-bar app for macOS that flies a friendly pink airplane across the screen ~5 minutes before each of Anaya's meetings.

## Build

```sh
swift build -c release
scripts/build_app.sh release     # produces build/Anaya's Co-Pilot.app
```

## Run

```sh
open "build/Anaya's Co-Pilot.app"
```

The first time it launches, a welcome card appears and macOS asks for calendar permission. Click **Allow** once and the co-pilot is on duty.

## Demo modes (no calendar needed)

```sh
build/Anaya\'s\ Co-Pilot.app/Contents/MacOS/AnayasCoPilot --demo
build/Anaya\'s\ Co-Pilot.app/Contents/MacOS/AnayasCoPilot --demo-special
build/Anaya\'s\ Co-Pilot.app/Contents/MacOS/AnayasCoPilot --demo-welcome
```

## Tests

```sh
swift test
```

## Install on Anaya's Mac

1. Double-click `AnayasCoPilot.dmg`.
2. Drag **Anaya's Co-Pilot** to **Applications**.
3. Double-click the app once. The welcome card appears.
4. macOS asks for calendar access: click **Allow**.
5. The app installs itself as a login item so it starts silently on every login. You can toggle this from the menu-bar menu under **Launch at login**.

## Sign & notarize (for distribution)

```sh
scripts/sign_notarize_dmg.sh
```

Requires a `Developer ID Application` cert in the keychain and a notarytool keychain profile named `notary-profile`.

## Personalize

All copy, colors, banner lines, welcome text, and special dates live in [`Sources/AnayasCoPilot/Personalization.swift`](Sources/AnayasCoPilot/Personalization.swift). No logic in there: safe to edit.
