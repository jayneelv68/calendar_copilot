import XCTest
@testable import AnayasCoPilot

final class BannerCopyTests: XCTestCase {
    func testUsesAttendeeWhenPresent() {
        let copy = BannerCopy(personalization: .default, rng: { 0 })
        let now = Date()
        let e = CopilotEvent(id: "1", title: "Sync", startDate: now,
                             isAllDay: false, firstAttendeeName: "Maya")
        let line = copy.bannerText(for: e, on: now)
        XCTAssertTrue(line.contains("Maya"), "should use attendee, got: \(line)")
    }

    func testUsesTitleWhenNoAttendee() {
        let copy = BannerCopy(personalization: .default, rng: { 0 })
        let now = Date()
        let e = CopilotEvent(id: "1", title: "Standup", startDate: now,
                             isAllDay: false, firstAttendeeName: nil)
        XCTAssertTrue(copy.bannerText(for: e, on: now).contains("Standup"))
    }

    func testFallbackWhenNoTitleOrAttendee() {
        let copy = BannerCopy(personalization: .default, rng: { 0 })
        let now = Date()
        let e = CopilotEvent(id: "1", title: nil, startDate: now,
                             isAllDay: false, firstAttendeeName: nil)
        XCTAssertEqual(copy.bannerText(for: e, on: now),
                       Personalization.default.bannerFallbackNoTitle)
    }

    func testSpecialDateOverride() {
        var p = Personalization.default
        let now = Date()
        let cal = Calendar.current
        let md = MonthDay(cal.component(.month, from: now), cal.component(.day, from: now))
        p.specialDates[md] = "Happy birthday, Anaya! 🎂"
        let copy = BannerCopy(personalization: p, rng: { 0 })
        let e = CopilotEvent(id: "1", title: "Anything", startDate: now,
                             isAllDay: false, firstAttendeeName: "X")
        XCTAssertEqual(copy.bannerText(for: e, on: now), "Happy birthday, Anaya! 🎂")
    }

    func testRotationAlwaysReturnsNonEmpty() {
        let p = Personalization.default
        let e = CopilotEvent(id: "1", title: "Sync", startDate: Date(),
                             isAllDay: false, firstAttendeeName: nil)
        for i in 0..<50 {
            let copy = BannerCopy(personalization: p, rng: { i })
            let line = copy.bannerText(for: e, on: Date())
            XCTAssertFalse(line.isEmpty)
            XCTAssertFalse(line.contains("{who}"), "placeholder not substituted: \(line)")
        }
    }

    func testGreetingPhases() {
        let cal = Calendar.current
        func at(_ hour: Int) -> Date {
            cal.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        }
        XCTAssertTrue(timeOfDayGreeting(for: at(8), name: "Anaya").hasPrefix("Morning"))
        XCTAssertTrue(timeOfDayGreeting(for: at(14), name: "Anaya").hasPrefix("Afternoon"))
        XCTAssertTrue(timeOfDayGreeting(for: at(19), name: "Anaya").hasPrefix("Evening"))
    }
}
