import SwiftUI

// All personalization for Anaya's Co-Pilot lives here.
// Tweak names, copy, colors, and special dates without touching app logic.

public struct MonthDay: Hashable {
    public let month: Int
    public let day: Int
    public init(_ m: Int, _ d: Int) { self.month = m; self.day = d }
}

public enum CopilotStyle {
    case warm    // default — playful, a touch cheesy, particles on
    case subtle  // quieter copy, fewer particles
}

public struct Personalization {
    public var ownerName: String = "Anaya"

    // First-launch welcome copy (used by WelcomeView).
    public var welcomeMessage: String = "Hi Anaya! Jayneel sent me to be your co-pilot."
    public var welcomeSubtitle: String =
        "I'll give you a 5-minute heads-up before each meeting so you can fly through your day."

    // Alternate welcome lines — uncomment to swap in.
    // public var welcomeMessage = "Welcome aboard, Anaya — your co-pilot is reporting for duty."
    // public var welcomeSubtitle = "I'll buzz by 5 minutes before every meeting. Smooth skies ahead."
    //
    // public var welcomeMessage = "Hi Anaya! I'm your tiny calendar co-pilot."
    // public var welcomeSubtitle = "Five-minute warnings before each meeting, delivered by airplane."
    //
    // public var welcomeMessage = "Anaya — meet your co-pilot."
    // public var welcomeSubtitle = "I keep an eye on your calendar so nothing sneaks up on you."

    // Banner lines. {who} = first attendee name, else event title.
    public var bannerLines: [String] = [
        "Anaya wheels up in 5 — {who}",
        "Cleared for takeoff, Anaya — {who} in 5 min",
        "Captain Anaya, your boarding call: {who} in 5",
        "Heads up Anaya — {who} on the runway",
        "5-minute warning, Anaya — {who} inbound",
    ]
    public var bannerFallbackNoTitle: String = "Anaya, something's on the runway in 5"

    // Visuals.
    public var planeColor: Color = Color(red: 1.0, green: 0.36, blue: 0.66)        // ~#FF5CA8
    public var bannerGradientStart: Color = Color(red: 1.0, green: 0.70, blue: 0.85)
    public var bannerGradientEnd: Color = Color(red: 0.78, green: 0.66, blue: 1.0)
    public var bannerTextColor: Color = Color.white

    // Animation timing.
    public var flightDurationSeconds: Double = 6.0
    public var leadMinutes: Int = 5

    // Special dates — map MonthDay → banner override.
    // Example (uncomment and edit):
    // public var specialDates: [MonthDay: String] = [
    //     MonthDay(7, 14): "Happy birthday, Anaya! 🎂 Skies are pink today.",
    // ]
    public var specialDates: [MonthDay: String] = [:]

    public var style: CopilotStyle = .warm

    public init() {}

    public static let `default` = Personalization()
}

// Greeting helper used in the menu-bar dropdown.
public func timeOfDayGreeting(for date: Date, name: String) -> String {
    let h = Calendar.current.component(.hour, from: date)
    let phase: String
    switch h {
    case 5..<12: phase = "Morning"
    case 12..<17: phase = "Afternoon"
    case 17..<22: phase = "Evening"
    default: phase = "Hi"
    }
    return "\(phase), \(name) ✨"
}
