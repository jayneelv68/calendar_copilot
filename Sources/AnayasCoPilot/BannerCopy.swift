import Foundation

public struct BannerCopy {
    public let personalization: Personalization
    public var rng: () -> Int = { Int.random(in: 0..<Int.max) }

    public init(personalization: Personalization = .default) {
        self.personalization = personalization
    }

    public init(personalization: Personalization, rng: @escaping () -> Int) {
        self.personalization = personalization
        self.rng = rng
    }

    public func bannerText(for event: CopilotEvent, on date: Date) -> String {
        let cal = Calendar.current
        let md = MonthDay(cal.component(.month, from: date), cal.component(.day, from: date))
        if let special = personalization.specialDates[md] {
            return special
        }
        let who: String?
        if let n = event.firstAttendeeName, !n.isEmpty { who = n }
        else if let t = event.title, !t.isEmpty { who = t }
        else { who = nil }

        guard let who else { return personalization.bannerFallbackNoTitle }

        let lines = personalization.bannerLines.isEmpty
            ? ["Anaya, {who} in 5"]
            : personalization.bannerLines
        let idx = abs(rng()) % lines.count
        return lines[idx].replacingOccurrences(of: "{who}", with: who)
    }
}
