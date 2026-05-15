import XCTest
@testable import IntakeTracker

final class CaffeineKineticsTests: XCTestCase {
    func testRemainingDoseAtHalfLifeIsHalf() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let fourHoursAgo = now.addingTimeInterval(-4 * 3600)

        let remaining = CaffeineKinetics.remainingDose(
            originalDoseMg: 120,
            since: fourHoursAgo,
            now: now,
            halfLifeHours: 4
        )

        XCTAssertEqual(remaining, 60, accuracy: 0.01)
    }

    func testCurrentBodyLoadAccumulatesMultipleDoses() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let twoHoursAgo = now.addingTimeInterval(-2 * 3600)
        let oneHourAgo = now.addingTimeInterval(-1 * 3600)

        let entries = [
            IntakeEntry(type: .caffeine, amount: 100, timestamp: twoHoursAgo, note: "Coffee"),
            IntakeEntry(type: .caffeine, amount: 80, timestamp: oneHourAgo, note: "Tea"),
            IntakeEntry(type: .water, amount: 1.0, timestamp: now)
        ]

        let load = CaffeineKinetics.currentBodyLoad(entries: entries, now: now, halfLifeHours: 5)

        // Rough expected value:
        // 100 * 0.5^(2/5) + 80 * 0.5^(1/5)
        XCTAssertEqual(load, 145.43, accuracy: 1.0)
    }

    func testIgnoresFutureEntries() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let future = now.addingTimeInterval(3600)

        let entries = [
            IntakeEntry(type: .caffeine, amount: 90, timestamp: future, note: "Future")
        ]

        let load = CaffeineKinetics.currentBodyLoad(entries: entries, now: now, halfLifeHours: 5)
        XCTAssertEqual(load, 0, accuracy: 0.001)
    }
}
