import Foundation

// Pure logic: given a clock, an event provider, and a set of already-fired IDs,
// return the events that should fire right now. Injectable for tests.
public final class AlertScheduler {
    public let leadSeconds: TimeInterval
    // id -> startDate at fire time. If the user reschedules an event, its
    // startDate changes and we treat that as a fresh commitment worth alerting.
    public var firedRecords: [String: Date] = [:]

    public init(leadMinutes: Int) {
        self.leadSeconds = TimeInterval(leadMinutes * 60)
    }

    public func eventsToFire(now: Date, events: [CopilotEvent]) -> [CopilotEvent] {
        var out: [CopilotEvent] = []
        for e in events {
            if e.isAllDay { continue }
            if firedRecords[e.id] == e.startDate { continue }
            let delta = e.startDate.timeIntervalSince(now)
            // Fire when start is within (0, leadSeconds].
            if delta > 0 && delta <= leadSeconds {
                out.append(e)
            }
        }
        return out
    }

    public func markFired(_ event: CopilotEvent) {
        firedRecords[event.id] = event.startDate
    }
}
