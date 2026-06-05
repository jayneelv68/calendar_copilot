import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let personalization = Personalization.default
    private let calendar = CalendarSource()
    private let scheduler = AlertScheduler(leadMinutes: Personalization.default.leadMinutes)
    private var pollTimer: Timer?
    private let firstLaunchKey = "hasLaunchedBefore"

    var demoMode: DemoMode = .none

    enum DemoMode {
        case none, flight, special, welcome
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installStatusItem()

        switch demoMode {
        case .flight:
            triggerDemoFlight(special: false)
            return
        case .special:
            triggerDemoFlight(special: true)
            return
        case .welcome:
            OverlayPresenter.shared.showWelcome(personalization: personalization) {}
            return
        case .none:
            break
        }

        let firstLaunch = !UserDefaults.standard.bool(forKey: firstLaunchKey)
        if firstLaunch {
            OverlayPresenter.shared.showWelcome(personalization: personalization) { [weak self] in
                UserDefaults.standard.set(true, forKey: self?.firstLaunchKey ?? "hasLaunchedBefore")
                self?.requestCalendarThenStart()
                // Default ON after first successful run.
                _ = LoginItem.setEnabled(true)
            }
        } else {
            requestCalendarThenStart()
        }
    }

    private func requestCalendarThenStart() {
        calendar.requestAccess { [weak self] granted in
            if !granted {
                fputs("[calendar] access not granted: running idle.\n", stderr)
            }
            self?.startPolling()
        }
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(pollTimer!, forMode: .common)
        // Re-tick as soon as the underlying event store changes (e.g. user
        // edits a meeting in Calendar.app), instead of waiting up to 30s.
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: calendar.store,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        tick()
    }

    private func tick() {
        let now = Date()
        let events = calendar.upcomingEvents(within: TimeInterval(personalization.leadMinutes * 60), from: now)
        let due = scheduler.eventsToFire(now: now, events: events)
        let df = ISO8601DateFormatter()
        fputs("[tick \(df.string(from: now))] window-visible=\(events.count) due=\(due.count)\n", stderr)
        for e in due {
            fputs("[FIRE] id=\(e.id) title=\(e.title ?? "nil") start=\(df.string(from: e.startDate))\n", stderr)
            scheduler.markFired(e)
            let copy = BannerCopy(personalization: personalization)
            let text = copy.bannerText(for: e, on: now)
            OverlayPresenter.shared.showFlight(bannerText: text, personalization: personalization)
        }
    }

    private func triggerDemoFlight(special: Bool) {
        var p = personalization
        if special {
            let cal = Calendar.current
            let now = Date()
            let md = MonthDay(cal.component(.month, from: now), cal.component(.day, from: now))
            p.specialDates[md] = "Happy day, Anaya! 💖 Pink skies just for you."
        }
        let copy = BannerCopy(personalization: p)
        let fake = CopilotEvent(id: "demo", title: "Standup with Jayneel",
                                startDate: Date().addingTimeInterval(300),
                                isAllDay: false, firstAttendeeName: "Jayneel")
        let text = copy.bannerText(for: fake, on: Date())
        OverlayPresenter.shared.showFlight(bannerText: text, personalization: p) {
            // Keep app alive in demo mode so menu bar stays around.
        }
    }

    // MARK: - Menu bar
    private var statusMenu: NSMenu!

    private func installStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = Self.makeMenubarPlaneIcon()
        }
        let menu = NSMenu()
        menu.delegate = self
        statusMenu = menu
        statusItem.menu = menu
        populateMenu(menu)
    }

    // Render the same horizontal PlaneShape used everywhere into a small template
    // image so the menu-bar icon matches the flight overlay and welcome card.
    // Template images get auto-tinted by macOS for light/dark menu-bar themes.
    private static func makeMenubarPlaneIcon() -> NSImage {
        let renderer = ImageRenderer(content:
            PlaneShape()
                .fill(Color.black)
                .frame(width: 22, height: 14)
                .padding(1)
        )
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let img = renderer.nsImage
            ?? NSImage(systemSymbolName: "airplane", accessibilityDescription: "Anaya's Co-Pilot")!
        img.isTemplate = true
        img.accessibilityDescription = "Anaya's Co-Pilot"
        return img
    }

    private func rebuildMenu() {
        guard let menu = statusMenu else { return }
        populateMenu(menu)
    }

    private func populateMenu(_ menu: NSMenu) {
        menu.removeAllItems()
        let greeting = NSMenuItem(title: timeOfDayGreeting(for: Date(), name: personalization.ownerName),
                                  action: nil, keyEquivalent: "")
        greeting.isEnabled = false
        menu.addItem(greeting)
        menu.addItem(.separator())

        menu.addItem(withTitle: "Test Flight ✈️", action: #selector(menuTestFlight), keyEquivalent: "t")
            .target = self
        menu.addItem(withTitle: "Replay welcome", action: #selector(menuReplayWelcome), keyEquivalent: "w")
            .target = self

        let upcomingHeader = NSMenuItem(title: "Upcoming", action: nil, keyEquivalent: "")
        upcomingHeader.isEnabled = false
        menu.addItem(.separator())
        menu.addItem(upcomingHeader)
        let upcoming = nextThreeEvents()
        if upcoming.isEmpty {
            let item = NSMenuItem(title: "  (none in the next hour)", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            let df = DateFormatter()
            df.dateFormat = "h:mm a"
            for e in upcoming {
                let title = "  \(df.string(from: e.startDate)): \(e.title ?? "(untitled)")"
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        let launchItem = NSMenuItem(title: "Launch at login",
                                    action: #selector(menuToggleLogin), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = LoginItem.isRegistered ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    private func nextThreeEvents() -> [CopilotEvent] {
        let evs = calendar.upcomingEvents(within: 3600, from: Date())
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
        return Array(evs.prefix(3))
    }

    @objc private func menuTestFlight() { triggerDemoFlight(special: false) }
    @objc private func menuReplayWelcome() {
        OverlayPresenter.shared.showWelcome(personalization: personalization) {}
    }
    @objc private func menuToggleLogin() {
        let nowOn = LoginItem.isRegistered
        _ = LoginItem.setEnabled(!nowOn)
        rebuildMenu()
    }

    // Re-query the calendar every time the menu opens so "Upcoming" reflects
    // the user's latest edits in Calendar.app, not whatever was true at launch.
    func menuNeedsUpdate(_ menu: NSMenu) {
        populateMenu(menu)
    }
}

