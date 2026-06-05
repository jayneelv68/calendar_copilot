import AppKit
import SwiftUI

// Borderless, click-through, always-on-top overlay window covering the main screen.
final class OverlayWindow: NSWindow {
    init(contentView: NSView) {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let frame = screen.frame
        super.init(contentRect: frame,
                   styleMask: .borderless,
                   backing: .buffered,
                   defer: false)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .screenSaver
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.contentView = contentView
        self.isReleasedWhenClosed = false
    }
}

// Welcome window — same overlay, but accepts clicks for the "Let's go" button.
final class WelcomeWindow: NSWindow {
    init(contentView: NSView) {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let frame = screen.frame
        super.init(contentRect: frame,
                   styleMask: .borderless,
                   backing: .buffered,
                   defer: false)
        self.isOpaque = false
        self.backgroundColor = NSColor.black.withAlphaComponent(0.001) // catches clicks
        self.hasShadow = false
        self.level = .screenSaver
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.contentView = contentView
        self.isReleasedWhenClosed = false
    }
}

@MainActor
final class OverlayPresenter {
    static let shared = OverlayPresenter()
    private var current: NSWindow?
    private var queue: [() -> Void] = []
    private var presenting = false

    func showFlight(bannerText: String, personalization: Personalization, completion: (() -> Void)? = nil) {
        enqueue { [weak self] in
            guard let self else { return }
            let view = PlaneFlightView(bannerText: bannerText, personalization: personalization) {
                self.dismissCurrent()
                completion?()
            }
            let host = NSHostingView(rootView: view)
            host.frame = (NSScreen.main ?? NSScreen.screens.first!).frame
            let win = OverlayWindow(contentView: host)
            self.current = win
            win.orderFrontRegardless()
        }
    }

    func showWelcome(personalization: Personalization, onDismiss: @escaping () -> Void) {
        enqueue { [weak self] in
            guard let self else { return }
            let view = WelcomeView(personalization: personalization) {
                self.dismissCurrent()
                onDismiss()
            }
            let host = NSHostingView(rootView: view)
            host.frame = (NSScreen.main ?? NSScreen.screens.first!).frame
            let win = WelcomeWindow(contentView: host)
            self.current = win
            NSApp.activate(ignoringOtherApps: true)
            win.makeKeyAndOrderFront(nil)
        }
    }

    private func enqueue(_ block: @escaping () -> Void) {
        queue.append(block)
        pump()
    }

    private func pump() {
        guard !presenting, !queue.isEmpty else { return }
        presenting = true
        let next = queue.removeFirst()
        next()
    }

    private func dismissCurrent() {
        current?.orderOut(nil)
        current = nil
        presenting = false
        // Small gap between queued animations.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.pump()
        }
    }
}
