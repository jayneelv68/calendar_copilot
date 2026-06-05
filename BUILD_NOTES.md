# Build Notes — decisions made along the way

## Project shape
- **Swift Package Manager**, not a hand-authored `.xcodeproj`. SPM is reliable from the terminal, supports both the executable target and XCTest target, and avoids a fragile `project.pbxproj`. The `.app` bundle is assembled by `scripts/build_app.sh` from the SPM binary plus a generated `Info.plist`.

## App architecture
- Entry point in `main.swift` wrapped in `MainActor.assumeIsolated { … }` to satisfy Swift 6 strict concurrency (Xcode 26 / Swift 6.3 enforces this).
- `AppDelegate` is `@MainActor`-isolated, owns the status item, the timer, the EventKit-backed `CalendarSource`, and the `AlertScheduler`.
- Pure logic (`AlertScheduler`, `BannerCopy`, `Personalization`, `CopilotEvent`) is split out so tests can run with fake clocks and fake events — no EventKit needed.
- The fullscreen overlay is a borderless `NSWindow` at `.screenSaver` level with `ignoresMouseEvents = true` so the plane never blocks Anaya's clicks. Collection behavior is `[.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]` so it appears on the active Space and over full-screen apps.
- The welcome window is a separate `WelcomeWindow` that *does* accept clicks (for the "Let's go ✈️" button).

## Menu bar
- `NSStatusItem` (not `MenuBarExtra`) because `MenuBarExtra` requires the SwiftUI `App` lifecycle, which conflicts with the `LSUIElement` accessory-app delegate pattern we already needed for fine-grained control over the welcome flow.

## Overlap & queueing
- `OverlayPresenter` is a single-flight queue. If two meetings start within seconds of each other, the second flight waits for the first to finish (plus a 0.3s gap). Avoids visual chaos.

## EventKit access
- On macOS 14+ we call `requestFullAccessToEvents` (the modern, granular API).
- If access isn't granted, `CalendarSource.upcomingEvents` returns `[]` rather than throwing — the app keeps running, just idle, logging once to stderr.

## Login item
- `SMAppService.mainApp.register()` — the modern API, available on macOS 13+. `SMLoginItemSetEnabled` is deprecated and not used.
- Registration is allowed to fail (e.g. when running unsigned from `~/calendar_copilot/build/`). The menu toggle reflects real state via `SMAppService.mainApp.status == .enabled`.
- After the first successful welcome dismissal, registration is attempted once (default ON).

## First-launch flag
- A simple `UserDefaults` bool (`hasLaunchedBefore`). Set after the welcome card is dismissed, so a crash during the welcome doesn't suppress it on the next launch.

## Banner copy
- `BannerCopy` takes an `rng: () -> Int` closure so tests can pin the line selection. `{who}` is replaced with the first attendee name when available, otherwise the event title, otherwise the fallback line is used (no substitution).
- Special-date check runs before random rotation; a matching `MonthDay` always wins.

## Plane visuals
- All drawn in code with `SwiftUI.Shape` — no PNG assets, no external dependencies. Warm pink fuselage, soft pink→lavender gradient banner, dotted contrail, optional heart/sparkle particles near the end (only in `.warm` style).

## Tests
- `AlertSchedulerTests` covers the 5-minute window, all-day skipping, re-fire suppression, and past-event ignoring.
- `BannerCopyTests` covers attendee/title/fallback selection, special-date override, and that random rotation always returns a valid non-empty line with `{who}` substituted.
- `FirstLaunchTests` uses a fresh `UserDefaults` suite per test to verify the show-once gate without polluting global state.
- `LoginItemTests` just verifies the API doesn't crash; the actual register/unregister path needs a real signed bundle in `/Applications`.

## Signing & notarization
- Hardened Runtime is enabled (`--options runtime`). Entitlements grant only `com.apple.security.personal-information.calendars` — nothing broader.
- DMG built with `hdiutil` (no third-party `create-dmg` dependency). Symlink to `/Applications` included so Anaya can drag-and-drop.
- Notarization expects a keychain profile named `notary-profile`. If it's missing, `sign_notarize_dmg.sh` errors out with the exact `store-credentials` command to create it (see README).

## Things deliberately not done
- No GitHub Actions / CI — per instructions.
- No custom icon — would need a real `.icns`, not worth a half-baked one.
- No DMG background image — fragile to script reliably.
