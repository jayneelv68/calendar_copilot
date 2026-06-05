import XCTest
@testable import AnayasCoPilot

final class AlertSchedulerTests: XCTestCase {
    func makeEvent(id: String = "e1",
                   minutesFromNow: Double,
                   isAllDay: Bool = false,
                   title: String? = "Standup",
                   attendee: String? = nil,
                   now: Date) -> CopilotEvent {
        return CopilotEvent(id: id, title: title,
                            startDate: now.addingTimeInterval(minutesFromNow * 60),
                            isAllDay: isAllDay, firstAttendeeName: attendee)
    }

    func testFiresWithinFiveMinutes() {
        let s = AlertScheduler(leadMinutes: 5)
        let now = Date()
        let e = makeEvent(minutesFromNow: 4 + 59/60.0, now: now) // 4m59s
        XCTAssertEqual(s.eventsToFire(now: now, events: [e]).map(\.id), ["e1"])
    }

    func testDoesNotFireBeyondLead() {
        let s = AlertScheduler(leadMinutes: 5)
        let now = Date()
        let e = makeEvent(minutesFromNow: 5.5, now: now)
        XCTAssertTrue(s.eventsToFire(now: now, events: [e]).isEmpty)
    }

    func testSkipsAllDay() {
        let s = AlertScheduler(leadMinutes: 5)
        let now = Date()
        let e = makeEvent(minutesFromNow: 1, isAllDay: true, now: now)
        XCTAssertTrue(s.eventsToFire(now: now, events: [e]).isEmpty)
    }

    func testDoesNotFireTwice() {
        let s = AlertScheduler(leadMinutes: 5)
        let now = Date()
        let e = makeEvent(minutesFromNow: 3, now: now)
        let first = s.eventsToFire(now: now, events: [e])
        XCTAssertEqual(first.count, 1)
        s.markFired(e.id)
        let second = s.eventsToFire(now: now, events: [e])
        XCTAssertTrue(second.isEmpty)
    }

    func testDoesNotFirePastEvents() {
        let s = AlertScheduler(leadMinutes: 5)
        let now = Date()
        let e = makeEvent(minutesFromNow: -1, now: now)
        XCTAssertTrue(s.eventsToFire(now: now, events: [e]).isEmpty)
    }
}
