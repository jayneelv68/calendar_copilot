import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
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
                fputs("[calendar] access not granted — running idle.\n", stderr)
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
        tick()
    }

    private func tick() {
        let now = Date()
        let events = calendar.upcomingEvents(within: TimeInterval(personalization.leadMinutes * 60), from: now)
        let due = scheduler.eventsToFire(now: now, events: events)
        for e in due {
            scheduler.markFired(e.id)
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
    private func installStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "airplane",
                                   accessibilityDescription: "Anaya's Co-Pilot")
        }
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
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
                let title = "  \(df.string(from: e.startDate)) — \(e.title ?? "(untitled)")"
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

        statusItem.menu = menu
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
}

