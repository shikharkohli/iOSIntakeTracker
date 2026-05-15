import XCTest
@testable import IntakeTracker

final class MetricKindTests: XCTestCase {
    func testAllCasesCoverIntakeTypes() {
        let kindTypes = Set(MetricKind.allCases.map { $0.intakeType })
        let allTypes = Set(IntakeType.allCases)
        XCTAssertEqual(kindTypes, allTypes)
    }

    func testTargetKeysAreUnique() {
        let keys = MetricKind.allCases.map { $0.targetKey }
        XCTAssertEqual(Set(keys).count, keys.count)
    }

    func testWaterFormatsAsGlasses() {
        XCTAssertEqual(MetricKind.water.format(2.5), Formatting.glasses(2.5))
    }

    func testCaffeineFormatsAsMg() {
        XCTAssertEqual(MetricKind.caffeine.format(220), Formatting.mg(220))
    }

    func testGlyphsNonEmpty() {
        for kind in MetricKind.allCases {
            XCTAssertFalse(kind.glyph.isEmpty, "\(kind) glyph empty")
        }
    }
}
