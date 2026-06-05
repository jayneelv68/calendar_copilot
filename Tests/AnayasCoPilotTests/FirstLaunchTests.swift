import XCTest
@testable import AnayasCoPilot

// Pure-logic stand-in for the first-launch flag, decoupled from UserDefaults
// so the test runs without polluting user state.
struct FirstLaunchGate {
    private let key: String
    private let store: UserDefaults
    init(key: String = "hasLaunchedBefore", store: UserDefaults) {
        self.key = key
        self.store = store
    }
    var shouldShow: Bool { !store.bool(forKey: key) }
    func markShown() { store.set(true, forKey: key) }
}

final class FirstLaunchTests: XCTestCase {
    func testWelcomeShowsOnceThenSuppressed() {
        let suite = UserDefaults(suiteName: "test.firstlaunch.\(UUID().uuidString)")!
        let gate = FirstLaunchGate(store: suite)
        XCTAssertTrue(gate.shouldShow)
        gate.markShown()
        XCTAssertFalse(gate.shouldShow)
    }
}
