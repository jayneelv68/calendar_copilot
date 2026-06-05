import Foundation

// Plain value type representing a calendar event we care about.
// Decoupled from EventKit so the alert logic can be unit-tested with fakes.
public struct CopilotEvent: Equatable, Hashable {
    public let id: String
    public let title: String?
    public let startDate: Date
    public let isAllDay: Bool
    public let firstAttendeeName: String?

    public init(id: String, title: String?, startDate: Date, isAllDay: Bool, firstAttendeeName: String?) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.isAllDay = isAllDay
        self.firstAttendeeName = firstAttendeeName
    }
}

public protocol EventProviding {
    func upcomingEvents(within window: TimeInterval, from now: Date) -> [CopilotEvent]
}

public protocol ClockProviding {
    func now() -> Date
}

public struct SystemClock: ClockProviding {
    public init() {}
    public func now() -> Date { Date() }
}
