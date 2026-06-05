import Foundation

// Pure logic: given a clock, an event provider, and a set of already-fired IDs,
// return the events that should fire right now. Injectable for tests.
public final class AlertScheduler {
    public let leadSeconds: TimeInterval
    public var firedIDs: Set<String> = []

    public init(leadMinutes: Int) {
        self.leadSeconds = TimeInterval(leadMinutes * 60)
    }

    public func eventsToFire(now: Date, events: [CopilotEvent]) -> [CopilotEvent] {
        var out: [CopilotEvent] = []
        for e in events {
            if e.isAllDay { continue }
            if firedIDs.contains(e.id) { continue }
            let delta = e.startDate.timeIntervalSince(now)
            // Fire when start is within (0, leadSeconds].
            // delta <= leadSeconds means we're within the 5-minute lead window.
            // delta > 0 means it hasn't started yet.
            if delta > 0 && delta <= leadSeconds {
                out.append(e)
            }
        }
        return out
    }

    public func markFired(_ id: String) { firedIDs.insert(id) }
}
