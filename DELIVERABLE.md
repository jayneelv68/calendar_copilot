# Anaya's Co-Pilot

A personalized macOS menu-bar app that flies a friendly pink airplane across the screen 5 minutes before each of Anaya's meetings.

## What it does

- Lives in the menu bar (no Dock icon).
- Reads events from Apple Calendar via EventKit.
- Every 30 seconds, scans for non-all-day events starting within the next 5 minutes.
- 5 minutes before each meeting, a fullscreen, click-through, always-on-top overlay shows a cute airplane towing a custom banner for ~6 seconds, then disappears.
- On the very first launch, a warm welcome card greets Anaya and triggers the calendar permission prompt.
- Auto-starts at login (toggleable from the menu).

## Build & run

```sh
swift build -c release
scripts/build_app.sh release
open "build/Anaya's Co-Pilot.app"
```

Tests: `swift test` (14 unit tests, all passing).

Demos: `--demo`, `--demo-special`, `--demo-welcome` on the binary inside the app bundle.

## Calendar permission

The very first launch triggers macOS's calendar consent dialog. Anaya clicks **Allow** once and that's it — the prompt comes from the system and cannot be auto-approved.

## Install for Anaya

1. Mount `AnayasCoPilot.dmg`.
2. Drag **Anaya's Co-Pilot** to **Applications**.
3. Double-click the app.
4. Approve calendar access when macOS asks.
5. The app registers itself as a login item — it'll start silently on every login from then on.

## Personalization

Everything Anaya-specific lives in [`Sources/AnayasCoPilot/Personalization.swift`](Sources/AnayasCoPilot/Personalization.swift):

- `ownerName` — currently "Anaya".
- `welcomeMessage`, `welcomeSubtitle` — first-launch hello (alternates are commented in the file).
- `bannerLines` — rotating playful copy; `{who}` is replaced by attendee or event title.
- `bannerFallbackNoTitle` — used when no name/title is available.
- `planeColor`, `bannerGradientStart`, `bannerGradientEnd`, `bannerTextColor` — visuals.
- `flightDurationSeconds`, `leadMinutes` — timing.
- `specialDates: [MonthDay: String]` — date overrides (e.g. birthday banner). Commented example included.
- `style` — `.warm` (default) or `.subtle`.

## Build status

- **v1.0** — builds cleanly, all 14 unit tests pass, `--demo`, `--demo-special`, `--demo-welcome` verified launching without crash, normal run verified staying alive in menu bar with graceful no-calendar-access fallback. Signing/notarization pending Developer ID cert + notary-profile.
