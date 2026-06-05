import XCTest
@testable import AnayasCoPilot

// LoginItem wraps SMAppService. In a unit-test process the app is not in /Applications
// and is not properly signed, so register/unregister are expected to fail gracefully.
// We assert the API doesn't crash and returns a Bool.
final class LoginItemTests: XCTestCase {
    func testIsRegisteredReturnsBool() {
        let _ = LoginItem.isRegistered
    }
    func testSetEnabledDoesNotCrash() {
        let _ = LoginItem.setEnabled(false)
    }
}
