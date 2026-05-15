import XCTest
@testable import IntakeTracker

final class HapticDebounceTests: XCTestCase {
    var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test.haptics")!
        defaults.removePersistentDomain(forName: "test.haptics")
    }

    func testGoalHitFiresFirstTime() {
        let fired = Haptic.shouldFireGoal(.water, defaults: defaults, now: Date())
        XCTAssertTrue(fired)
    }

    func testGoalHitDoesNotFireTwiceSameDay() {
        let now = Date()
        _ = Haptic.shouldFireGoal(.water, defaults: defaults, now: now)
        let second = Haptic.shouldFireGoal(.water, defaults: defaults, now: now.addingTimeInterval(3600))
        XCTAssertFalse(second)
    }

    func testGoalHitFiresAgainNextDay() {
        let day1 = Date(timeIntervalSince1970: 1_700_000_000)
        let day2 = day1.addingTimeInterval(86_400 * 1.5)
        _ = Haptic.shouldFireGoal(.water, defaults: defaults, now: day1)
        let next = Haptic.shouldFireGoal(.water, defaults: defaults, now: day2)
        XCTAssertTrue(next)
    }

    func testGoalHitIndependentPerMetric() {
        let now = Date()
        _ = Haptic.shouldFireGoal(.water, defaults: defaults, now: now)
        let caffeine = Haptic.shouldFireGoal(.caffeine, defaults: defaults, now: now)
        XCTAssertTrue(caffeine)
    }
}
