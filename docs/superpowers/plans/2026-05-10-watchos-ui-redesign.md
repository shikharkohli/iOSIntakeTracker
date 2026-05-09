# watchOS UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the watchOS UI with a polished Apple Health/Fitness aesthetic — hero rings, mini-ring summary list, vibrant palette, expanded complications, Smart Stack relevance providers, and typed haptics.

**Architecture:** Add a `Shared/Design/` component layer (theme, hero ring, mini-ring row, action chip, haptics) and a `Shared/Models/MetricKind.swift` enum that centralizes per-metric color/glyph/format/target. Rewrite the seven watch views as compositions over those primitives. Split and extend complication widgets to support all four `accessory*` families plus Smart Stack rectangular tiles with relevance providers.

**Tech Stack:** SwiftUI, WidgetKit, WatchKit, AppIntents, WatchConnectivity. xcodegen for project generation. XCTest for unit tests.

**Pre-flight:** All file additions go inside existing source roots (`Shared/`, `IntakeTracker Watch App/`, `IntakeTracker Complications/`, `IntakeTrackerTests/`). After adding files, run `xcodegen` once at the end to regenerate `IntakeTracker.xcodeproj`.

---

## Task 1: `MetricKind` enum + tests

**Files:**
- Create: `Shared/Models/MetricKind.swift`
- Create: `IntakeTrackerTests/MetricKindTests.swift`

- [ ] **Step 1: Write failing test**

```swift
// IntakeTrackerTests/MetricKindTests.swift
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
```

- [ ] **Step 2: Run test to verify failure**

Run: `xcodebuild test -project IntakeTracker.xcodeproj -scheme IntakeTracker -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:IntakeTrackerTests/MetricKindTests 2>&1 | tail -20`

Expected: build failure — `MetricKind` not found.

- [ ] **Step 3: Implement `MetricKind`**

```swift
// Shared/Models/MetricKind.swift
import SwiftUI

enum MetricKind: String, CaseIterable, Identifiable {
    case water, caffeine, fullness, weight, waist

    var id: String { rawValue }

    var intakeType: IntakeType {
        switch self {
        case .water:    return .water
        case .caffeine: return .caffeine
        case .fullness: return .fullness
        case .weight:   return .weight
        case .waist:    return .waist
        }
    }

    var displayName: String { intakeType.displayName }

    var glyph: String { intakeType.systemImage }

    var color: Color {
        switch self {
        case .water:    return WatchTheme.Color.water
        case .caffeine: return WatchTheme.Color.caffeine
        case .fullness: return WatchTheme.Color.fullness
        case .weight:   return WatchTheme.Color.weight
        case .waist:    return WatchTheme.Color.waist
        }
    }

    var targetKey: String {
        switch self {
        case .water:    return "target.waterGlasses"
        case .caffeine: return "target.caffeineMg"
        case .fullness: return "target.mealsPerDay"
        case .weight:   return "target.weightKg"
        case .waist:    return "target.waistCm"
        }
    }

    var defaultTarget: Double {
        switch self {
        case .water:    return 8
        case .caffeine: return 400
        case .fullness: return 4
        case .weight:   return 70
        case .waist:    return 80
        }
    }

    func format(_ value: Double) -> String {
        switch self {
        case .water:    return Formatting.glasses(value)
        case .caffeine: return Formatting.mg(value)
        case .fullness: return "\(Int(value))"
        case .weight:   return Formatting.weight(kg: value)
        case .waist:    return Formatting.waist(cm: value)
        }
    }
}
```

Note: this references `WatchTheme.Color.*` which Task 2 creates. Implement Task 2 immediately after Task 1's implementation step but before running tests — or stub the colors temporarily to `Color.blue` etc. Recommended: do Task 2 first if you prefer strict ordering. Plan keeps Task 1 first because the enum drives the rest of the app.

- [ ] **Step 4: Run tests to verify pass**

Run after Task 2 implementation step:
`xcodebuild test -project IntakeTracker.xcodeproj -scheme IntakeTracker -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:IntakeTrackerTests/MetricKindTests 2>&1 | tail -20`

Expected: all 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Shared/Models/MetricKind.swift IntakeTrackerTests/MetricKindTests.swift
git commit -m "feat: add MetricKind enum centralizing per-metric metadata"
```

---

## Task 2: `WatchTheme` palette tokens

**Files:**
- Create: `Shared/Design/WatchTheme.swift`

- [ ] **Step 1: Implement theme**

```swift
// Shared/Design/WatchTheme.swift
import SwiftUI

enum WatchTheme {
    enum Color {
        static let water    = SwiftUI.Color(red: 0.12, green: 0.92, blue: 0.94) // #1EEAEF
        static let caffeine = SwiftUI.Color(red: 1.00, green: 0.62, blue: 0.04) // #FF9F0A
        static let fullness = SwiftUI.Color(red: 0.57, green: 0.91, blue: 0.16) // #92E82A
        static let weight   = SwiftUI.Color(red: 0.98, green: 0.07, blue: 0.31) // #FA114F
        static let waist    = SwiftUI.Color(red: 0.75, green: 0.35, blue: 0.95) // #BF5AF2
        static let track    = SwiftUI.Color.white.opacity(0.12)
    }

    enum Spacing {
        static let pageH: CGFloat = 6
        static let stack: CGFloat = 8
        static let chipGap: CGFloat = 6
    }

    enum Radius {
        static let chip: CGFloat = 14
        static let tile: CGFloat = 12
    }

    enum Stroke {
        static let heroRing: CGFloat = 10
        static let miniRing: CGFloat = 3
    }
}
```

- [ ] **Step 2: Build watch target**

Run: `xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Shared/Design/WatchTheme.swift
git commit -m "feat: add WatchTheme palette tokens"
```

---

## Task 3: `Haptic` helper + debounce tests

**Files:**
- Create: `Shared/Design/Haptics.swift`
- Create: `IntakeTrackerTests/HapticDebounceTests.swift`

- [ ] **Step 1: Write failing test**

```swift
// IntakeTrackerTests/HapticDebounceTests.swift
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
```

- [ ] **Step 2: Run test to verify failure**

Run: `xcodebuild test -project IntakeTracker.xcodeproj -scheme IntakeTracker -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:IntakeTrackerTests/HapticDebounceTests 2>&1 | tail -20`

Expected: build failure — `Haptic` not found.

- [ ] **Step 3: Implement `Haptic`**

```swift
// Shared/Design/Haptics.swift
import Foundation
#if canImport(WatchKit)
import WatchKit
#endif

enum Haptic {
    static func tapLog() {
        #if canImport(WatchKit)
        WKInterfaceDevice.current().play(.click)
        #endif
    }

    static func crownStep() {
        #if canImport(WatchKit)
        WKInterfaceDevice.current().play(.click)
        #endif
    }

    /// Fires `.success` once per metric per local day.
    static func goalReached(_ metric: MetricKind, defaults: UserDefaults = .standard, now: Date = Date()) {
        guard shouldFireGoal(metric, defaults: defaults, now: now) else { return }
        #if canImport(WatchKit)
        WKInterfaceDevice.current().play(.success)
        #endif
    }

    /// Pure debounce check — testable. Returns true when the haptic should fire,
    /// and records the day so the next same-day call returns false.
    @discardableResult
    static func shouldFireGoal(_ metric: MetricKind, defaults: UserDefaults, now: Date) -> Bool {
        let key = "haptic.goal.\(metric.rawValue).day"
        let today = Calendar.current.startOfDay(for: now).timeIntervalSince1970
        let last = defaults.double(forKey: key)
        if last == today { return false }
        defaults.set(today, forKey: key)
        return true
    }
}
```

- [ ] **Step 4: Run tests to verify pass**

Run: `xcodebuild test -project IntakeTracker.xcodeproj -scheme IntakeTracker -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:IntakeTrackerTests/HapticDebounceTests 2>&1 | tail -20`

Expected: 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Shared/Design/Haptics.swift IntakeTrackerTests/HapticDebounceTests.swift
git commit -m "feat: add Haptic helper with goal-hit debounce"
```

---

## Task 4: `HeroRing` component

**Files:**
- Create: `Shared/Design/HeroRing.swift`

- [ ] **Step 1: Implement**

```swift
// Shared/Design/HeroRing.swift
import SwiftUI

struct HeroRing: View {
    let metric: MetricKind
    let value: Double
    let target: Double
    var caption: String?
    var centerOverride: String? = nil

    private var fraction: Double {
        guard target > 0 else { return 0 }
        return min(value / target, 1.0)
    }

    private var centerText: String {
        if let centerOverride { return centerOverride }
        return metric.format(value)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(WatchTheme.Color.track, style: StrokeStyle(lineWidth: WatchTheme.Stroke.heroRing, lineCap: .round))
            Circle()
                .trim(from: 0, to: CGFloat(fraction))
                .stroke(
                    LinearGradient(
                        colors: [metric.color, metric.color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: WatchTheme.Stroke.heroRing, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.smooth, value: fraction)

            VStack(spacing: 2) {
                Text(centerText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(metric.color)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                if let caption {
                    Text(caption)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 130, height: 130)
    }
}

#Preview {
    HeroRing(metric: .water, value: 5, target: 8, caption: "of 8 cups")
}
```

- [ ] **Step 2: Build watch target**

Run: `xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Shared/Design/HeroRing.swift
git commit -m "feat: add HeroRing component"
```

---

## Task 5: `MiniRingRow` component

**Files:**
- Create: `Shared/Design/MiniRingRow.swift`

- [ ] **Step 1: Implement**

```swift
// Shared/Design/MiniRingRow.swift
import SwiftUI

struct MiniRingRow: View {
    let metric: MetricKind
    let value: Double
    let target: Double
    var onTap: (() -> Void)? = nil

    private var fraction: Double {
        guard target > 0 else { return 0 }
        return min(value / target, 1.0)
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(WatchTheme.Color.track, lineWidth: WatchTheme.Stroke.miniRing)
                    Circle()
                        .trim(from: 0, to: CGFloat(fraction))
                        .stroke(metric.color, style: StrokeStyle(lineWidth: WatchTheme.Stroke.miniRing, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 22, height: 22)

                Text(metric.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(metric.format(value))
                    .font(.system(size: 13, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(metric.color)
            }
            .padding(.vertical, 6)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5)
            }
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}

#Preview {
    VStack(spacing: 0) {
        MiniRingRow(metric: .water, value: 5, target: 8)
        MiniRingRow(metric: .caffeine, value: 220, target: 400)
    }
    .padding()
    .background(.black)
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Shared/Design/MiniRingRow.swift
git commit -m "feat: add MiniRingRow component"
```

---

## Task 6: `QuickActionChip` component

**Files:**
- Create: `Shared/Design/QuickActionChip.swift`

- [ ] **Step 1: Implement**

```swift
// Shared/Design/QuickActionChip.swift
import SwiftUI

struct QuickActionChip: View {
    let label: String
    var glyph: String? = nil
    var wide: Bool = false
    var tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let glyph {
                    Image(systemName: glyph)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(tint)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .frame(maxWidth: wide ? .infinity : nil)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WatchTheme.Radius.chip))
            .overlay(
                RoundedRectangle(cornerRadius: WatchTheme.Radius.chip)
                    .stroke(tint.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        HStack { QuickActionChip(label: "½", tint: .cyan) {} ; QuickActionChip(label: "1", tint: .cyan) {} }
        QuickActionChip(label: "Bottle", wide: true, tint: .cyan) {}
    }
    .padding()
    .background(.black)
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Shared/Design/QuickActionChip.swift
git commit -m "feat: add QuickActionChip component"
```

---

## Task 7: Rewrite `WatchSummaryView`

**Files:**
- Modify: `IntakeTracker Watch App/Views/WatchSummaryView.swift` (full rewrite)

- [ ] **Step 1: Replace file contents**

```swift
// IntakeTracker Watch App/Views/WatchSummaryView.swift
import SwiftUI

struct WatchSummaryView: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage("target.waterGlasses") private var waterTarget: Double = 8
    @AppStorage("target.caffeineMg") private var caffeineTarget: Double = 400
    @AppStorage("target.mealsPerDay") private var mealsTarget: Double = 4
    @AppStorage("target.weightKg") private var weightTarget: Double = 70
    @AppStorage("target.waistCm") private var waistTarget: Double = 80

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(MetricKind.allCases) { kind in
                        MiniRingRow(
                            metric: kind,
                            value: currentValue(for: kind),
                            target: target(for: kind)
                        )
                    }
                }
                .padding(.horizontal, WatchTheme.Spacing.pageH)
            }
            .navigationTitle("Today")
        }
    }

    private func currentValue(for kind: MetricKind) -> Double {
        switch kind {
        case .water, .caffeine, .fullness:
            return store.total(of: kind.intakeType)
        case .weight, .waist:
            return store.latestEntry(type: kind.intakeType)?.amount ?? 0
        }
    }

    private func target(for kind: MetricKind) -> Double {
        switch kind {
        case .water:    return waterTarget
        case .caffeine: return caffeineTarget
        case .fullness: return mealsTarget
        case .weight:   return weightTarget
        case .waist:    return waistTarget
        }
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add "IntakeTracker Watch App/Views/WatchSummaryView.swift"
git commit -m "refactor: rewrite WatchSummaryView as MiniRingRow list"
```

---

## Task 8: Rewrite `WatchWaterView`

**Files:**
- Modify: `IntakeTracker Watch App/Views/WatchWaterView.swift` (full rewrite)

- [ ] **Step 1: Replace contents**

```swift
// IntakeTracker Watch App/Views/WatchWaterView.swift
import SwiftUI

struct WatchWaterView: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage("target.waterGlasses") private var target: Double = 8
    @State private var isLogging = false

    private var total: Double { store.total(of: .water) }

    var body: some View {
        NavigationStack {
            VStack(spacing: WatchTheme.Spacing.stack) {
                HeroRing(
                    metric: .water,
                    value: total,
                    target: target,
                    caption: "of \(Formatting.glasses(target))"
                )

                HStack(spacing: WatchTheme.Spacing.chipGap) {
                    QuickActionChip(label: "½", tint: WatchTheme.Color.water) { log(0.5) }
                    QuickActionChip(label: "1",  tint: WatchTheme.Color.water) { log(1.0) }
                }
                QuickActionChip(label: "Bottle", wide: true, tint: WatchTheme.Color.water) { log(2.0) }
            }
            .padding(.horizontal, WatchTheme.Spacing.pageH)
        }
    }

    private func log(_ glasses: Double) {
        guard !isLogging else { return }
        isLogging = true
        let pre = total
        store.add(IntakeEntry(type: .water, amount: glasses))
        Haptic.tapLog()
        if pre < target, total >= target {
            Haptic.goalReached(.water)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isLogging = false }
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add "IntakeTracker Watch App/Views/WatchWaterView.swift"
git commit -m "refactor: rewrite WatchWaterView with HeroRing + chips"
```

---

## Task 9: Rewrite `WatchCaffeineView`

**Files:**
- Modify: `IntakeTracker Watch App/Views/WatchCaffeineView.swift` (full rewrite)

- [ ] **Step 1: Replace contents**

```swift
// IntakeTracker Watch App/Views/WatchCaffeineView.swift
import SwiftUI

struct WatchCaffeineView: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage("target.caffeineMg") private var target: Double = 400
    @State private var isLogging = false

    private var total: Double { store.total(of: .caffeine) }

    var body: some View {
        NavigationStack {
            VStack(spacing: WatchTheme.Spacing.stack) {
                HeroRing(
                    metric: .caffeine,
                    value: total,
                    target: target,
                    caption: "of \(Formatting.mg(target))"
                )

                HStack(spacing: WatchTheme.Spacing.chipGap) {
                    QuickActionChip(label: "Esp", tint: WatchTheme.Color.caffeine) { log(63) }
                    QuickActionChip(label: "Cup", tint: WatchTheme.Color.caffeine) { log(95) }
                }
                QuickActionChip(label: "Energy", wide: true, tint: WatchTheme.Color.caffeine) { log(160) }
            }
            .padding(.horizontal, WatchTheme.Spacing.pageH)
        }
    }

    private func log(_ mg: Double) {
        guard !isLogging else { return }
        isLogging = true
        let pre = total
        store.add(IntakeEntry(type: .caffeine, amount: mg))
        Haptic.tapLog()
        if pre < target, total >= target {
            Haptic.goalReached(.caffeine)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isLogging = false }
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add "IntakeTracker Watch App/Views/WatchCaffeineView.swift"
git commit -m "refactor: rewrite WatchCaffeineView with HeroRing + chips"
```

---

## Task 10: Rewrite `WatchFullnessView`

**Files:**
- Modify: `IntakeTracker Watch App/Views/WatchFullnessView.swift` (full rewrite)

- [ ] **Step 1: Replace contents**

```swift
// IntakeTracker Watch App/Views/WatchFullnessView.swift
import SwiftUI

struct WatchFullnessView: View {
    @EnvironmentObject private var store: IntakeStore
    @State private var pickerMeal: MealType?

    private var loggedCount: Int {
        MealType.allCases.reduce(0) { $0 + (store.mealFullness(for: $1) == nil ? 0 : 1) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: WatchTheme.Spacing.stack) {
                HeroRing(
                    metric: .fullness,
                    value: Double(loggedCount),
                    target: Double(MealType.allCases.count),
                    caption: "meals logged",
                    centerOverride: "\(loggedCount)/\(MealType.allCases.count)"
                )

                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 4) {
                    ForEach(MealType.allCases) { meal in
                        Button {
                            pickerMeal = meal
                        } label: {
                            VStack(spacing: 2) {
                                if let entry = store.mealFullness(for: meal),
                                   let level = FullnessLevel(rawValue: Int(entry.amount)) {
                                    Text(level.emoji).font(.title3)
                                } else {
                                    Text(meal.emoji).font(.title3).opacity(0.35)
                                }
                                Text(meal.displayName)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WatchTheme.Radius.tile))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, WatchTheme.Spacing.pageH)
            .sheet(item: $pickerMeal) { meal in
                FullnessPickerSheet(meal: meal)
            }
        }
    }
}

private struct FullnessPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: IntakeStore
    let meal: MealType

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text(meal.displayName).font(.headline)
                ForEach(FullnessLevel.allCases) { level in
                    Button {
                        store.add(IntakeEntry(type: .fullness, amount: Double(level.rawValue), meal: meal))
                        Haptic.tapLog()
                        dismiss()
                    } label: {
                        HStack {
                            Text(level.emoji).font(.title3)
                            Text(level.label).font(.system(size: 13))
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WatchTheme.Radius.tile))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, WatchTheme.Spacing.pageH)
        }
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add "IntakeTracker Watch App/Views/WatchFullnessView.swift"
git commit -m "refactor: rewrite WatchFullnessView with HeroRing + meal grid"
```

---

## Task 11: Rewrite `WatchWeightView` with crown stepper

**Files:**
- Modify: `IntakeTracker Watch App/Views/WatchWeightView.swift` (full rewrite)

- [ ] **Step 1: Replace contents**

```swift
// IntakeTracker Watch App/Views/WatchWeightView.swift
import SwiftUI

struct WatchWeightView: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage("target.weightKg") private var target: Double = 70
    @State private var crownValue: Double = 70
    @FocusState private var inputFocused: Bool

    private var latest: Double {
        store.latestEntry(type: .weight)?.amount ?? 0
    }

    private var ringFraction: Double {
        guard target > 0, latest > 0 else { return 0 }
        return max(0, 1 - min(abs(latest - target) / target, 1))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: WatchTheme.Spacing.stack) {
                HeroRing(
                    metric: .weight,
                    value: ringFraction * target,
                    target: target,
                    caption: latest > 0 ? "kg" : "tap to log",
                    centerOverride: latest > 0 ? Formatting.weight(kg: latest) : "—"
                )

                Text(Formatting.weight(kg: crownValue))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(WatchTheme.Color.weight)
                    .focusable()
                    .focused($inputFocused)
                    .digitalCrownRotation(
                        $crownValue,
                        from: 30, through: 200, by: 0.1,
                        sensitivity: .medium,
                        isContinuous: false,
                        isHapticFeedbackEnabled: true
                    )

                QuickActionChip(label: "Save", wide: true, tint: WatchTheme.Color.weight) {
                    store.add(IntakeEntry(type: .weight, amount: crownValue))
                    Haptic.tapLog()
                }
            }
            .padding(.horizontal, WatchTheme.Spacing.pageH)
            .onAppear {
                crownValue = latest > 0 ? latest : target
                inputFocused = true
            }
        }
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add "IntakeTracker Watch App/Views/WatchWeightView.swift"
git commit -m "refactor: rewrite WatchWeightView with crown stepper"
```

---

## Task 12: Rewrite `WatchWaistView` with crown stepper

**Files:**
- Modify: `IntakeTracker Watch App/Views/WatchWaistView.swift` (full rewrite)

- [ ] **Step 1: Replace contents**

```swift
// IntakeTracker Watch App/Views/WatchWaistView.swift
import SwiftUI

struct WatchWaistView: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage("target.waistCm") private var target: Double = 80
    @State private var crownValue: Double = 80
    @FocusState private var inputFocused: Bool

    private var latest: Double {
        store.latestEntry(type: .waist)?.amount ?? 0
    }

    private var ringFraction: Double {
        guard target > 0, latest > 0 else { return 0 }
        return max(0, 1 - min(abs(latest - target) / target, 1))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: WatchTheme.Spacing.stack) {
                HeroRing(
                    metric: .waist,
                    value: ringFraction * target,
                    target: target,
                    caption: latest > 0 ? "cm" : "tap to log",
                    centerOverride: latest > 0 ? Formatting.waist(cm: latest) : "—"
                )

                Text(Formatting.waist(cm: crownValue))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(WatchTheme.Color.waist)
                    .focusable()
                    .focused($inputFocused)
                    .digitalCrownRotation(
                        $crownValue,
                        from: 40, through: 150, by: 0.5,
                        sensitivity: .medium,
                        isContinuous: false,
                        isHapticFeedbackEnabled: true
                    )

                QuickActionChip(label: "Save", wide: true, tint: WatchTheme.Color.waist) {
                    store.add(IntakeEntry(type: .waist, amount: crownValue))
                    Haptic.tapLog()
                }
            }
            .padding(.horizontal, WatchTheme.Spacing.pageH)
            .onAppear {
                crownValue = latest > 0 ? latest : target
                inputFocused = true
            }
        }
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add "IntakeTracker Watch App/Views/WatchWaistView.swift"
git commit -m "refactor: rewrite WatchWaistView with crown stepper"
```

---

## Task 13: Verify `WatchRootView` page routing still works

**Files:**
- Read: `IntakeTracker Watch App/Views/WatchRootView.swift`

The existing TabView already routes between summary + 5 metric pages. No structural change required, but verify the page enum still references views by their existing names. If the file was structured around an internal `WatchPage` enum that hardcodes views, no changes needed.

- [ ] **Step 1: Read the file**

Run: `cat "IntakeTracker Watch App/Views/WatchRootView.swift"`

- [ ] **Step 2: Build full target to confirm integration**

Run: `xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Manual launch in simulator**

Run: `xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build` then open Simulator and launch app. Swipe vertically through pages: Summary → Water → Caffeine → Fullness → Weight → Waist. Each page should render new HeroRing + chips/grid/stepper.

If any page still uses old layout, it means the file wasn't rewritten in earlier tasks — backtrack to the relevant task.

- [ ] **Step 4: Commit only if changes were needed**

If no changes: skip commit. Otherwise:

```bash
git add "IntakeTracker Watch App/Views/WatchRootView.swift"
git commit -m "refactor: align WatchRootView with redesigned pages"
```

---

## Task 14: `IntakeStore` — log timestamps in App Group + extend complication data

**Files:**
- Modify: `Shared/Store/IntakeStore.swift`

- [ ] **Step 1: Modify `writeComplicationData()`**

Current method writes water/caffeine totals. Add:

Find in `Shared/Store/IntakeStore.swift` the body of `writeComplicationData()` and add after the existing `group.set(...)` calls (before the `WidgetCenter.shared.reloadAllTimelines()` line):

```swift
// Latest log timestamps for Smart Stack relevance
let lastWater = entries.first(where: { $0.type == .water })?.timestamp
let lastCaffeine = entries.first(where: { $0.type == .caffeine })?.timestamp
group.set(lastWater?.timeIntervalSince1970 ?? 0, forKey: "complication.lastWaterLogged")
group.set(lastCaffeine?.timeIntervalSince1970 ?? 0, forKey: "complication.lastCaffeineLogged")

// Fullness count + latest weight for new circular widgets
let mealsLogged = MealType.allCases.reduce(0) { count, meal in
    count + (mealFullness(for: meal, on: today) == nil ? 0 : 1)
}
group.set(mealsLogged, forKey: "complication.fullnessCount")
let latestWeight = latestEntry(type: .weight)?.amount ?? 0
group.set(latestWeight, forKey: "complication.weightLatest")

// Mirror weight target
let weightTarget = defaults.double(forKey: "target.weightKg")
group.set(weightTarget > 0 ? weightTarget : 70, forKey: "target.weightKg")
```

- [ ] **Step 2: Build all targets**

Run: `xcodebuild -project IntakeTracker.xcodeproj -scheme IntakeTracker -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Run unit tests**

Run: `xcodebuild test -project IntakeTracker.xcodeproj -scheme IntakeTracker -destination 'platform=iOS Simulator,name=iPhone 15' 2>&1 | tail -10`

Expected: all existing tests still PASS.

- [ ] **Step 4: Commit**

```bash
git add Shared/Store/IntakeStore.swift
git commit -m "feat: extend complication data with timestamps + fullness/weight"
```

---

## Task 15: Split `ProgressWidgets.swift` → restyled circular widgets

**Files:**
- Modify: `IntakeTracker Complications/ProgressWidgets.swift` → rename concept to **CircularProgressWidget.swift**
- Create: `IntakeTracker Complications/CircularProgressWidget.swift`
- Delete: `IntakeTracker Complications/ProgressWidgets.swift` (after migration)

- [ ] **Step 1: Create new file with all four circular widgets**

```swift
// IntakeTracker Complications/CircularProgressWidget.swift
import WidgetKit
import SwiftUI

private let appGroupID = "group.com.intaketracker.shared"

private struct CircularEntry: TimelineEntry {
    let date: Date
    let total: Double
    let target: Double
    var fraction: Double { target > 0 ? min(total / target, 1.0) : 0 }
}

private struct CircularRingView: View {
    let metric: MetricKind
    let total: Double
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let line = max(3, s * 0.11)
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.55), style: StrokeStyle(lineWidth: line, lineCap: .round))
                Circle()
                    .trim(from: 0, to: CGFloat(fraction))
                    .stroke(metric.color, style: StrokeStyle(lineWidth: line, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: metric.glyph)
                    .font(.system(size: max(10, s * 0.30), weight: .semibold, design: .rounded))
                    .foregroundStyle(metric.color)
                    .widgetAccentable()
            }
            .padding(max(2, s * 0.06))
        }
    }
}

private struct CircularProvider: TimelineProvider {
    let metric: MetricKind
    let totalKey: String
    let targetKey: String
    let defaultTarget: Double
    let dayGated: Bool

    func placeholder(in context: Context) -> CircularEntry {
        CircularEntry(date: Date(), total: defaultTarget * 0.5, target: defaultTarget)
    }
    func getSnapshot(in context: Context, completion: @escaping (CircularEntry) -> Void) { completion(current()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CircularEntry>) -> Void) {
        completion(Timeline(entries: [current()], policy: .after(Date().addingTimeInterval(15 * 60))))
    }
    private func current() -> CircularEntry {
        let d = UserDefaults(suiteName: appGroupID) ?? .standard
        let total: Double
        if dayGated {
            let todayStart = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
            let stored = d.double(forKey: "complication.dayStart")
            total = (stored == todayStart) ? d.double(forKey: totalKey) : 0
        } else {
            total = d.double(forKey: totalKey)
        }
        let raw = d.double(forKey: targetKey)
        let target = raw > 0 ? raw : defaultTarget
        return CircularEntry(date: Date(), total: total, target: target)
    }
}

struct WaterCircularWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "water.circular",
            provider: CircularProvider(metric: .water, totalKey: "complication.waterTotal", targetKey: "target.waterGlasses", defaultTarget: 8, dayGated: true)
        ) { entry in
            CircularRingView(metric: .water, total: entry.total, fraction: entry.fraction)
                .containerBackground(for: .widget) { }
                .widgetURL(URL(string: "intaketracker://open/water")!)
        }
        .configurationDisplayName("Water")
        .description("Water progress ring.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct CaffeineCircularWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "caffeine.circular",
            provider: CircularProvider(metric: .caffeine, totalKey: "complication.caffeineBodyLoad", targetKey: "target.caffeineMg", defaultTarget: 400, dayGated: false)
        ) { entry in
            CircularRingView(metric: .caffeine, total: entry.total, fraction: entry.fraction)
                .containerBackground(for: .widget) { }
                .widgetURL(URL(string: "intaketracker://open/caffeine")!)
        }
        .configurationDisplayName("Caffeine")
        .description("Caffeine bloodstream load.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct FullnessCircularWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "fullness.circular",
            provider: CircularProvider(metric: .fullness, totalKey: "complication.fullnessCount", targetKey: "target.mealsPerDay", defaultTarget: 4, dayGated: true)
        ) { entry in
            CircularRingView(metric: .fullness, total: entry.total, fraction: entry.fraction)
                .containerBackground(for: .widget) { }
                .widgetURL(URL(string: "intaketracker://open/fullness")!)
        }
        .configurationDisplayName("Meals")
        .description("Meals logged today.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct WeightCircularWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "weight.circular",
            provider: CircularProvider(metric: .weight, totalKey: "complication.weightLatest", targetKey: "target.weightKg", defaultTarget: 70, dayGated: false)
        ) { entry in
            CircularRingView(metric: .weight, total: entry.total, fraction: entry.fraction)
                .containerBackground(for: .widget) { }
                .widgetURL(URL(string: "intaketracker://open/weight")!)
        }
        .configurationDisplayName("Weight")
        .description("Latest weight reading.")
        .supportedFamilies([.accessoryCircular])
    }
}
```

- [ ] **Step 2: Delete old `ProgressWidgets.swift`**

```bash
rm "IntakeTracker Complications/ProgressWidgets.swift"
```

- [ ] **Step 3: Build (will fail until bundle updated)**

Run: `xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Complications" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build 2>&1 | tail -10`

Expected: build error about `WaterProgressWidget` / `CaffeineProgressWidget` not found in bundle. Bundle is updated in Task 20.

- [ ] **Step 4: Stage but do not commit yet**

```bash
git add "IntakeTracker Complications/CircularProgressWidget.swift"
git rm "IntakeTracker Complications/ProgressWidgets.swift"
```

Commit deferred to Task 20 after bundle update.

---

## Task 16: `CornerProgressWidget`

**Files:**
- Create: `IntakeTracker Complications/CornerProgressWidget.swift`

- [ ] **Step 1: Implement**

```swift
// IntakeTracker Complications/CornerProgressWidget.swift
import WidgetKit
import SwiftUI

private let appGroupID = "group.com.intaketracker.shared"

private struct CornerEntry: TimelineEntry {
    let date: Date
    let total: Double
    let target: Double
    var fraction: Double { target > 0 ? min(total / target, 1.0) : 0 }
}

private struct CornerProvider: TimelineProvider {
    let totalKey: String
    let targetKey: String
    let defaultTarget: Double
    let dayGated: Bool

    func placeholder(in context: Context) -> CornerEntry {
        CornerEntry(date: Date(), total: defaultTarget * 0.5, target: defaultTarget)
    }
    func getSnapshot(in context: Context, completion: @escaping (CornerEntry) -> Void) { completion(current()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CornerEntry>) -> Void) {
        completion(Timeline(entries: [current()], policy: .after(Date().addingTimeInterval(15 * 60))))
    }
    private func current() -> CornerEntry {
        let d = UserDefaults(suiteName: appGroupID) ?? .standard
        let total: Double
        if dayGated {
            let todayStart = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
            let stored = d.double(forKey: "complication.dayStart")
            total = (stored == todayStart) ? d.double(forKey: totalKey) : 0
        } else {
            total = d.double(forKey: totalKey)
        }
        let raw = d.double(forKey: targetKey)
        return CornerEntry(date: Date(), total: total, target: raw > 0 ? raw : defaultTarget)
    }
}

struct WaterCornerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "water.corner",
            provider: CornerProvider(totalKey: "complication.waterTotal", targetKey: "target.waterGlasses", defaultTarget: 8, dayGated: true)
        ) { entry in
            Image(systemName: "drop.fill")
                .foregroundStyle(WatchTheme.Color.water)
                .widgetAccentable()
                .widgetLabel {
                    Gauge(value: entry.fraction) {
                        Text(MetricKind.water.format(entry.total))
                    }
                    .gaugeStyle(.accessoryLinearCapacity)
                    .tint(WatchTheme.Color.water)
                }
                .containerBackground(for: .widget) { }
                .widgetURL(URL(string: "intaketracker://open/water")!)
        }
        .configurationDisplayName("Water Corner")
        .description("Curved corner water progress.")
        .supportedFamilies([.accessoryCorner])
    }
}

struct CaffeineCornerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "caffeine.corner",
            provider: CornerProvider(totalKey: "complication.caffeineBodyLoad", targetKey: "target.caffeineMg", defaultTarget: 400, dayGated: false)
        ) { entry in
            Image(systemName: "cup.and.saucer.fill")
                .foregroundStyle(WatchTheme.Color.caffeine)
                .widgetAccentable()
                .widgetLabel {
                    Gauge(value: entry.fraction) {
                        Text(MetricKind.caffeine.format(entry.total))
                    }
                    .gaugeStyle(.accessoryLinearCapacity)
                    .tint(WatchTheme.Color.caffeine)
                }
                .containerBackground(for: .widget) { }
                .widgetURL(URL(string: "intaketracker://open/caffeine")!)
        }
        .configurationDisplayName("Caffeine Corner")
        .description("Curved corner caffeine progress.")
        .supportedFamilies([.accessoryCorner])
    }
}
```

- [ ] **Step 2: Build (still fails until bundle updated)**

Skip — bundle update in Task 20 will resolve.

- [ ] **Step 3: Stage**

```bash
git add "IntakeTracker Complications/CornerProgressWidget.swift"
```

---

## Task 17: `InlineProgressWidget`

**Files:**
- Create: `IntakeTracker Complications/InlineProgressWidget.swift`

- [ ] **Step 1: Implement**

```swift
// IntakeTracker Complications/InlineProgressWidget.swift
import WidgetKit
import SwiftUI

private let appGroupID = "group.com.intaketracker.shared"

private struct InlineEntry: TimelineEntry {
    let date: Date
    let water: Double
    let caffeine: Double
}

private struct InlineProvider: TimelineProvider {
    func placeholder(in context: Context) -> InlineEntry { InlineEntry(date: Date(), water: 4, caffeine: 200) }
    func getSnapshot(in context: Context, completion: @escaping (InlineEntry) -> Void) { completion(current()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<InlineEntry>) -> Void) {
        completion(Timeline(entries: [current()], policy: .after(Date().addingTimeInterval(15 * 60))))
    }
    private func current() -> InlineEntry {
        let d = UserDefaults(suiteName: appGroupID) ?? .standard
        let todayStart = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        let stored = d.double(forKey: "complication.dayStart")
        let water = (stored == todayStart) ? d.double(forKey: "complication.waterTotal") : 0
        let caffeine = d.double(forKey: "complication.caffeineBodyLoad")
        return InlineEntry(date: Date(), water: water, caffeine: caffeine)
    }
}

struct IntakeInlineWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "intake.inline", provider: InlineProvider()) { entry in
            Text("\(Image(systemName: "drop.fill")) \(MetricKind.water.format(entry.water))  \(Image(systemName: "cup.and.saucer.fill")) \(MetricKind.caffeine.format(entry.caffeine))")
                .containerBackground(for: .widget) { }
                .widgetURL(URL(string: "intaketracker://open/summary")!)
        }
        .configurationDisplayName("Intake Inline")
        .description("Single-line water + caffeine summary.")
        .supportedFamilies([.accessoryInline])
    }
}
```

- [ ] **Step 2: Stage**

```bash
git add "IntakeTracker Complications/InlineProgressWidget.swift"
```

---

## Task 18: Smart Stack — Hydration widget + relevance + tests

**Files:**
- Create: `IntakeTracker Complications/SmartStackWidgets.swift`
- Create: `IntakeTrackerTests/HydrationRelevanceTests.swift`

- [ ] **Step 1: Write failing relevance test**

```swift
// IntakeTrackerTests/HydrationRelevanceTests.swift
import XCTest
@testable import IntakeTracker

final class HydrationRelevanceTests: XCTestCase {
    func testNoLogReturnsRelevant() {
        let score = HydrationRelevance.score(lastLogged: nil, now: Date())
        XCTAssertGreaterThanOrEqual(score, 0.5)
    }

    func testRecentLogReturnsZero() {
        let now = Date()
        let recent = now.addingTimeInterval(-30 * 60) // 30min ago
        XCTAssertEqual(HydrationRelevance.score(lastLogged: recent, now: now), 0)
    }

    func testTwoHourGapReturnsHigh() {
        let now = Date()
        let then = now.addingTimeInterval(-7200 - 60) // just over 2h
        XCTAssertGreaterThanOrEqual(HydrationRelevance.score(lastLogged: then, now: now), 0.8)
    }

    func testLongGapCapsAtOne() {
        let now = Date()
        let then = now.addingTimeInterval(-86_400)
        XCTAssertLessThanOrEqual(HydrationRelevance.score(lastLogged: then, now: now), 1.0)
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `xcodebuild test -project IntakeTracker.xcodeproj -scheme IntakeTracker -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:IntakeTrackerTests/HydrationRelevanceTests 2>&1 | tail -20`

Expected: build failure — `HydrationRelevance` not found.

- [ ] **Step 3: Implement `SmartStackWidgets.swift`**

```swift
// IntakeTracker Complications/SmartStackWidgets.swift
import WidgetKit
import SwiftUI

private let appGroupID = "group.com.intaketracker.shared"

// MARK: - Hydration relevance

enum HydrationRelevance {
    static let gapThreshold: TimeInterval = 7200 // 2h

    /// Returns 0..1 score. 0 if recently logged, climbing toward 1 as gap grows.
    static func score(lastLogged: Date?, now: Date) -> Double {
        guard let lastLogged else { return 0.6 } // never logged today → mid-priority
        let gap = now.timeIntervalSince(lastLogged)
        if gap < gapThreshold { return 0 }
        let over = gap - gapThreshold
        return min(1.0, 0.8 + over / 21_600) // hits 1.0 at gap >= 8h
    }
}

// MARK: - Caffeine relevance (used in Task 19)

enum CaffeineRelevance {
    /// Surface in afternoon (13:00–18:00 local) when bloodstream load < 100mg
    /// below target — i.e., user has headroom and may want to log a coffee.
    static func score(bodyLoad: Double, target: Double, now: Date, calendar: Calendar = .current) -> Double {
        let hour = calendar.component(.hour, from: now)
        guard hour >= 13, hour < 18 else { return 0 }
        let headroom = target - bodyLoad
        guard headroom > 0, headroom < 100 else { return 0 }
        return 0.85
    }
}

// MARK: - Hydration Smart Stack widget

private struct HydrationSmartEntry: TimelineEntry {
    let date: Date
    let total: Double
    let target: Double
    let lastLogged: Date?
    var fraction: Double { target > 0 ? min(total / target, 1.0) : 0 }
    var hint: String {
        guard let lastLogged else { return "no log yet" }
        let mins = Int(Date().timeIntervalSince(lastLogged) / 60)
        if mins < 60 { return "logged \(mins)m ago" }
        return "logged \(mins / 60)h ago"
    }
}

private struct HydrationProvider: TimelineProvider {
    func placeholder(in context: Context) -> HydrationSmartEntry {
        HydrationSmartEntry(date: Date(), total: 4, target: 8, lastLogged: nil)
    }
    func getSnapshot(in context: Context, completion: @escaping (HydrationSmartEntry) -> Void) { completion(current()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HydrationSmartEntry>) -> Void) {
        completion(Timeline(entries: [current()], policy: .after(Date().addingTimeInterval(15 * 60))))
    }
    func relevances() async -> WidgetRelevances<Void> {
        let entry = current()
        let s = HydrationRelevance.score(lastLogged: entry.lastLogged, now: Date())
        guard s > 0 else { return WidgetRelevances([]) }
        return WidgetRelevances([
            WidgetRelevanceEntry(context: .init(kind: .userActivity), score: Float(s))
        ])
    }
    private func current() -> HydrationSmartEntry {
        let d = UserDefaults(suiteName: appGroupID) ?? .standard
        let todayStart = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        let stored = d.double(forKey: "complication.dayStart")
        let total = (stored == todayStart) ? d.double(forKey: "complication.waterTotal") : 0
        let raw = d.double(forKey: "target.waterGlasses")
        let target = raw > 0 ? raw : 8
        let ts = d.double(forKey: "complication.lastWaterLogged")
        let last = ts > 0 ? Date(timeIntervalSince1970: ts) : nil
        return HydrationSmartEntry(date: Date(), total: total, target: target, lastLogged: last)
    }
}

struct HydrationSmartStackWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "smartstack.hydration", provider: HydrationProvider()) { entry in
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(WatchTheme.Color.track, lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: CGFloat(entry.fraction))
                        .stroke(WatchTheme.Color.water, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "drop.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(WatchTheme.Color.water)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Water")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(MetricKind.water.format(entry.total)) of \(Int(entry.target))")
                        .font(.headline)
                    Text(entry.hint)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Button(intent: {
                    var i = LogWaterIntent()
                    i.quantity = .oneGlass
                    return i
                }()) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(WatchTheme.Color.water)
                }
                .buttonStyle(.plain)
            }
            .containerBackground(for: .widget) { }
            .widgetURL(URL(string: "intaketracker://open/water")!)
        }
        .configurationDisplayName("Hydration Reminder")
        .description("Shows in Smart Stack when hydration needs attention.")
        .supportedFamilies([.accessoryRectangular])
    }
}
```

- [ ] **Step 4: Run tests**

Run: `xcodebuild test -project IntakeTracker.xcodeproj -scheme IntakeTracker -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:IntakeTrackerTests/HydrationRelevanceTests 2>&1 | tail -20`

Expected: 4 tests PASS.

- [ ] **Step 5: Stage**

```bash
git add "IntakeTracker Complications/SmartStackWidgets.swift" IntakeTrackerTests/HydrationRelevanceTests.swift
```

---

## Task 19: Smart Stack — Caffeine widget + relevance tests

**Files:**
- Modify: `IntakeTracker Complications/SmartStackWidgets.swift` (append)
- Create: `IntakeTrackerTests/CaffeineRelevanceTests.swift`

- [ ] **Step 1: Write failing relevance test**

```swift
// IntakeTrackerTests/CaffeineRelevanceTests.swift
import XCTest
@testable import IntakeTracker

final class CaffeineRelevanceTests: XCTestCase {
    private func date(hour: Int) -> Date {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 1; comps.day = 15
        comps.hour = hour
        return Calendar(identifier: .gregorian).date(from: comps)!
    }

    func testMorningReturnsZero() {
        XCTAssertEqual(CaffeineRelevance.score(bodyLoad: 350, target: 400, now: date(hour: 9)), 0)
    }

    func testAfternoonHighHeadroomReturnsZero() {
        // headroom = 400 → too much, not relevant ("user nowhere near limit")
        XCTAssertEqual(CaffeineRelevance.score(bodyLoad: 0, target: 400, now: date(hour: 14)), 0)
    }

    func testAfternoonLowHeadroomReturnsScore() {
        // headroom = 50 → user is close to cutoff, surface widget
        XCTAssertGreaterThan(CaffeineRelevance.score(bodyLoad: 350, target: 400, now: date(hour: 14)), 0.5)
    }

    func testEveningReturnsZero() {
        XCTAssertEqual(CaffeineRelevance.score(bodyLoad: 350, target: 400, now: date(hour: 19)), 0)
    }

    func testOverTargetReturnsZero() {
        XCTAssertEqual(CaffeineRelevance.score(bodyLoad: 450, target: 400, now: date(hour: 14)), 0)
    }
}
```

- [ ] **Step 2: Run test — should already pass**

`CaffeineRelevance.score` was implemented in Task 18.

Run: `xcodebuild test -project IntakeTracker.xcodeproj -scheme IntakeTracker -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:IntakeTrackerTests/CaffeineRelevanceTests 2>&1 | tail -20`

Expected: 5 tests PASS.

- [ ] **Step 3: Append Caffeine Smart Stack widget to `SmartStackWidgets.swift`**

Append at end of `IntakeTracker Complications/SmartStackWidgets.swift`:

```swift
// MARK: - Caffeine Smart Stack widget

private struct CaffeineSmartEntry: TimelineEntry {
    let date: Date
    let bodyLoad: Double
    let target: Double
    var fraction: Double { target > 0 ? min(bodyLoad / target, 1.0) : 0 }
    var headroom: Int { max(0, Int(target - bodyLoad)) }
}

private struct CaffeineSmartProvider: TimelineProvider {
    func placeholder(in context: Context) -> CaffeineSmartEntry {
        CaffeineSmartEntry(date: Date(), bodyLoad: 200, target: 400)
    }
    func getSnapshot(in context: Context, completion: @escaping (CaffeineSmartEntry) -> Void) { completion(current()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CaffeineSmartEntry>) -> Void) {
        completion(Timeline(entries: [current()], policy: .after(Date().addingTimeInterval(15 * 60))))
    }
    func relevances() async -> WidgetRelevances<Void> {
        let entry = current()
        let s = CaffeineRelevance.score(bodyLoad: entry.bodyLoad, target: entry.target, now: Date())
        guard s > 0 else { return WidgetRelevances([]) }
        return WidgetRelevances([
            WidgetRelevanceEntry(context: .init(kind: .userActivity), score: Float(s))
        ])
    }
    private func current() -> CaffeineSmartEntry {
        let d = UserDefaults(suiteName: appGroupID) ?? .standard
        let bodyLoad = d.double(forKey: "complication.caffeineBodyLoad")
        let raw = d.double(forKey: "target.caffeineMg")
        return CaffeineSmartEntry(date: Date(), bodyLoad: bodyLoad, target: raw > 0 ? raw : 400)
    }
}

struct CaffeineSmartStackWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "smartstack.caffeine", provider: CaffeineSmartProvider()) { entry in
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(WatchTheme.Color.track, lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: CGFloat(entry.fraction))
                        .stroke(WatchTheme.Color.caffeine, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(WatchTheme.Color.caffeine)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Caffeine")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(MetricKind.caffeine.format(entry.bodyLoad))")
                        .font(.headline)
                    Text("\(entry.headroom)mg headroom")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Button(intent: {
                    var i = LogCaffeineIntent()
                    i.quantity = .coffee
                    return i
                }()) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(WatchTheme.Color.caffeine)
                }
                .buttonStyle(.plain)
            }
            .containerBackground(for: .widget) { }
            .widgetURL(URL(string: "intaketracker://open/caffeine")!)
        }
        .configurationDisplayName("Caffeine Headroom")
        .description("Shows in Smart Stack on afternoons near the daily limit.")
        .supportedFamilies([.accessoryRectangular])
    }
}
```

- [ ] **Step 4: Stage**

```bash
git add IntakeTrackerTests/CaffeineRelevanceTests.swift "IntakeTracker Complications/SmartStackWidgets.swift"
```

---

## Task 20: Update bundle, delete `QuickLaunchWidgets.swift`, regenerate project

**Files:**
- Modify: `IntakeTracker Complications/IntakeTracker_ComplicationsBundle.swift`
- Delete: `IntakeTracker Complications/QuickLaunchWidgets.swift`

- [ ] **Step 1: Read current bundle**

Run: `cat "IntakeTracker Complications/IntakeTracker_ComplicationsBundle.swift"`

- [ ] **Step 2: Replace bundle contents**

```swift
// IntakeTracker Complications/IntakeTracker_ComplicationsBundle.swift
import WidgetKit
import SwiftUI

@main
struct IntakeTrackerComplicationsBundle: WidgetBundle {
    var body: some Widget {
        // Circular
        WaterCircularWidget()
        CaffeineCircularWidget()
        FullnessCircularWidget()
        WeightCircularWidget()
        // Corner
        WaterCornerWidget()
        CaffeineCornerWidget()
        // Inline
        IntakeInlineWidget()
        // Rectangular Smart Stack
        HydrationSmartStackWidget()
        CaffeineSmartStackWidget()
    }
}
```

- [ ] **Step 3: Delete `QuickLaunchWidgets.swift`**

```bash
rm "IntakeTracker Complications/QuickLaunchWidgets.swift"
```

- [ ] **Step 4: Regenerate Xcode project**

Run: `xcodegen 2>&1 | tail -5`

Expected: project.xcodeproj regenerated with all new files included.

If `xcodegen` not installed: `brew install xcodegen` first.

- [ ] **Step 5: Build all targets**

Run:
```bash
xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Complications" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build 2>&1 | tail -10
xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build 2>&1 | tail -10
xcodebuild -project IntakeTracker.xcodeproj -scheme IntakeTracker -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -10
```

Expected: all three BUILD SUCCEEDED.

- [ ] **Step 6: Run full test suite**

Run: `xcodebuild test -project IntakeTracker.xcodeproj -scheme IntakeTracker -destination 'platform=iOS Simulator,name=iPhone 15' 2>&1 | tail -20`

Expected: all tests PASS (MetricKindTests, HapticDebounceTests, HydrationRelevanceTests, CaffeineRelevanceTests, plus pre-existing tests).

- [ ] **Step 7: Commit consolidated changes**

```bash
git add "IntakeTracker Complications/IntakeTracker_ComplicationsBundle.swift" IntakeTracker.xcodeproj
git rm "IntakeTracker Complications/QuickLaunchWidgets.swift"
git commit -m "feat: expanded complication families + Smart Stack widgets

- Split ProgressWidgets into per-family files (Circular/Corner/Inline)
- Add Fullness + Weight circular complications
- Add HydrationSmartStackWidget with >2h-gap relevance scoring
- Add CaffeineSmartStackWidget with afternoon/headroom relevance
- Drop QuickLaunchWidgets (superseded by Button(intent:) in Smart Stack)
- Regenerate xcodeproj"
```

---

## Task 21: Manual QA pass

**Files:** none

- [ ] **Step 1: Install on watchOS simulator**

Run app from Xcode on Apple Watch Series 9 simulator (or paired with iPhone 15 sim).

- [ ] **Step 2: Verify watch pages**

For each metric: empty / mid-progress / goal-hit
- [ ] Summary scrolls, all 5 metrics show correct rings + values
- [ ] Water page: HeroRing animates, ½/1/Bottle chips log correctly, haptic fires
- [ ] Caffeine: Esp/Cup/Energy chips log
- [ ] Fullness: meal grid opens picker, selecting level updates ring
- [ ] Weight: crown rotates value, native haptic detents, Save commits
- [ ] Waist: same as Weight with `by: 0.5` step

- [ ] **Step 3: Verify goal-hit haptic**

Set water target to 2. Log 1 + 1. On the second log, verify `.success` haptic plays. Log a third — no haptic. Reset day (manual `defaults delete` or simulator date change), verify next log triggers again.

- [ ] **Step 4: Verify complications**

Long-press watch face → Edit → add each new complication family:
- [ ] accessoryCircular: Water, Caffeine, Fullness, Weight all render
- [ ] accessoryCorner: Water + Caffeine show curved arc + label
- [ ] accessoryInline: shows "💧 X · ☕ Y"

- [ ] **Step 5: Verify Smart Stack**

In simulator, manipulate App Group defaults to fast-forward `lastWaterLogged` to 3h ago:
```bash
xcrun simctl spawn booted defaults write group.com.intaketracker.shared complication.lastWaterLogged -double $(date -v-3H +%s)
```
Then open Smart Stack on watch. Hydration tile should appear. Tap "+" → verify water count increments without app open.

- [ ] **Step 6: Final commit**

If any QA-driven fixes were made, commit them:
```bash
git add -A
git commit -m "fix: QA pass adjustments"
```

---

## Verification checklist (run before declaring done)

```bash
# All targets build clean
xcodebuild -project IntakeTracker.xcodeproj -scheme IntakeTracker -destination 'platform=iOS Simulator,name=iPhone 15' build
xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build
xcodebuild -project IntakeTracker.xcodeproj -scheme "IntakeTracker Complications" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build

# All tests pass
xcodebuild test -project IntakeTracker.xcodeproj -scheme IntakeTracker -destination 'platform=iOS Simulator,name=iPhone 15'

# Branch state
git log --oneline watchos-ui-redesign ^main
```

Expected: 3× BUILD SUCCEEDED, all tests PASS, commit history shows ~20 task commits since `main`.
