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

// Fade helpers on NSWindow so the overlay/welcome never pop in or out abruptly.
extension NSWindow {
    func fadeIn(duration: TimeInterval = 0.35, activate: Bool = false) {
        self.alphaValue = 0
        if activate {
            NSApp.activate(ignoringOtherApps: true)
            self.makeKeyAndOrderFront(nil)
        } else {
            self.orderFrontRegardless()
        }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
        }
    }

    func fadeOut(duration: TimeInterval = 0.35, completion: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.orderOut(nil)
            completion()
        })
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
            win.fadeIn(duration: 0.30)
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
            win.fadeIn(duration: 0.40, activate: true)
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
        guard let win = current else { presenting = false; pump(); return }
        current = nil
        win.fadeOut(duration: 0.35) { [weak self] in
            self?.presenting = false
            // Small gap between queued animations.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.pump()
            }
        }
    }
}
