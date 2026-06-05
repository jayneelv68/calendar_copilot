import Foundation
import EventKit

// EventKit-backed EventProviding. Falls back to empty when access is missing.
public final class CalendarSource: EventProviding {
    public let store = EKEventStore()
    private(set) var hasAccess: Bool = false

    public init() {}

    public func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { granted, err in
                if let err { fputs("[calendar] access error: \(err)\n", stderr) }
                self.hasAccess = granted
                DispatchQueue.main.async { completion(granted) }
            }
        } else {
            store.requestAccess(to: .event) { granted, _ in
                self.hasAccess = granted
                DispatchQueue.main.async { completion(granted) }
            }
        }
    }

    public func upcomingEvents(within window: TimeInterval, from now: Date) -> [CopilotEvent] {
        let status: EKAuthorizationStatus
        if #available(macOS 14.0, *) {
            status = EKEventStore.authorizationStatus(for: .event)
            // .fullAccess raw value = 5 on macOS 14; treat anything authorized as ok.
        } else {
            status = EKEventStore.authorizationStatus(for: .event)
        }
        guard status.rawValue >= 3 || hasAccess else { return [] }

        let end = now.addingTimeInterval(window + 60)
        let cals = store.calendars(for: .event)
        guard !cals.isEmpty else { return [] }
        let predicate = store.predicateForEvents(withStart: now.addingTimeInterval(-60),
                                                 end: end, calendars: cals)
        let evs = store.events(matching: predicate)
        return evs.map { e in
            let attendee = e.attendees?.compactMap { $0.name }.first { !$0.isEmpty }
            return CopilotEvent(
                id: e.eventIdentifier ?? UUID().uuidString,
                title: e.title,
                startDate: e.startDate,
                isAllDay: e.isAllDay,
                firstAttendeeName: attendee
            )
        }
    }
}
