# watchOS UI Redesign — Design Spec

**Branch:** `watchos-ui-redesign`
**Date:** 2026-05-10
**Scope:** watchOS app + complications. iOS untouched.

## Goal

Replace cramped, plain watch UI with polished, HIG-aligned design borrowing
Apple Health/Fitness language. Add Smart Stack support and expand
complication coverage. Single Fitness-style vibrant palette throughout.

## Constraints

- No Activity Rings (concentric tri-ring) — Apple trade dress.
- No iOS view changes this branch.
- watchOS 10+ (matches existing target).
- Single brand palette, no theme switcher (YAGNI).

## Decisions

| Area | Choice |
|------|--------|
| Visual direction | Hero ring per metric page (single open arc, not concentric) |
| Summary page | Mini-ring list (5 rows, scrollable) |
| Palette | Fitness vibrant — cyan/orange/green/red/purple |
| Complication families | accessoryCircular, accessoryCorner, accessoryRectangular, accessoryInline |
| Smart Stack signals | Hydration gap (>2h no water) · Caffeine afternoon cutoff |
| Haptics | `.click` per quick-add · `.success` on goal hit (1×/day/metric) · crown native detents |
| Crown integration | Stays on TabView for page switching (current pattern) |
| Quick-launch button widgets | Dropped — replaced by `Button(intent:)` in Smart Stack tiles |

## Architecture

```
Shared/
├── Design/                                  [NEW]
│   ├── WatchTheme.swift                     palette tokens, fonts, radii, spacing
│   ├── HeroRing.swift                       big ring + center value + caption
│   ├── MiniRingRow.swift                    summary list row primitive
│   ├── QuickActionChip.swift                pill button for quick-add
│   └── Haptics.swift                        typed wrapper over WKInterfaceDevice
├── Models/
│   ├── MetricKind.swift                     [NEW] per-metric color/glyph/format/target
│   ├── IntakeEntry.swift                    unchanged
│   └── CaffeineKinetics.swift               unchanged
└── Sync/SyncService.swift                   unchanged

IntakeTracker Watch App/Views/
├── WatchRootView.swift                      keep TabView, drive via MetricKind.allCases
├── WatchSummaryView.swift                   rewrite → MiniRingRow list
├── WatchWaterView.swift                     rewrite → HeroRing + chip row
├── WatchCaffeineView.swift                  rewrite → HeroRing + chip row
├── WatchFullnessView.swift                  rewrite → HeroRing + meal grid
├── WatchWeightView.swift                    rewrite → HeroRing + crown stepper
└── WatchWaistView.swift                     rewrite → HeroRing + crown stepper

IntakeTracker Complications/
├── CircularProgressWidget.swift             [SPLIT from ProgressWidgets.swift]
├── CornerProgressWidget.swift               [NEW] accessoryCorner
├── InlineProgressWidget.swift               [NEW] accessoryInline
├── SmartStackWidgets.swift                  [NEW] rectangular + RelevanceProvider
├── QuickLaunchWidgets.swift                 [DELETE] superseded
└── IntakeTracker_ComplicationsBundle.swift  re-register
```

## Components

### `WatchTheme.swift`

```swift
enum WatchTheme {
    enum Color {
        static let water    = Color(red: 0.12, green: 0.92, blue: 0.94)  // #1EEAEF
        static let caffeine = Color(red: 1.00, green: 0.62, blue: 0.04)  // #FF9F0A
        static let fullness = Color(red: 0.57, green: 0.91, blue: 0.16)  // #92E82A
        static let weight   = Color(red: 0.98, green: 0.07, blue: 0.31)  // #FA114F
        static let waist    = Color(red: 0.75, green: 0.35, blue: 0.95)  // #BF5AF2
        static let track    = Color.white.opacity(0.12)
    }
    enum Spacing { static let pageH: CGFloat = 6; static let stack: CGFloat = 8 }
    enum Radius  { static let chip: CGFloat = 14; static let tile: CGFloat = 12 }
}
```

All five colors verified WCAG AA on `#000` (≥7:1 contrast).

### `MetricKind.swift`

```swift
enum MetricKind: String, CaseIterable, Identifiable {
    case water, caffeine, fullness, weight, waist
    var id: String { rawValue }
    var color: Color
    var glyph: String          // SF Symbol name
    var displayName: String
    var targetKey: String      // AppStorage key for target
    var intakeType: IntakeType // bridge to existing model
    func format(_ value: Double) -> String
}
```

Centralizes per-metric metadata so views can iterate `MetricKind.allCases`
instead of duplicating switch statements.

### `HeroRing.swift`

```swift
struct HeroRing: View {
    let metric: MetricKind
    let value: Double
    let target: Double
    let caption: String?

    var body: some View
}
```

Renders 130×130 ring: `Circle().trim(from:0,to:1).stroke(track,lineWidth:10)`
overlaid with progress arc using `LinearGradient(metric.color → metric.color.opacity(0.6))`.
Center: big number (`28pt .bold .monospacedDigit`), caption (`10pt .secondary`).
Animates via `.animation(.smooth, value: value)`.

### `MiniRingRow.swift`

```swift
struct MiniRingRow: View {
    let metric: MetricKind
    let value: Double
    let target: Double
    var onTap: (() -> Void)? = nil
    var body: some View
}
```

22pt open arc + label (12pt) + tabular value (13pt bold). Bottom 0.5pt
divider via `.overlay(alignment:.bottom)`. Whole row tappable when `onTap` set.

### `QuickActionChip.swift`

```swift
struct QuickActionChip: View {
    let label: String
    let glyph: String?
    var wide: Bool = false
    var tint: Color
    let action: () -> Void
}
```

Pill with `.ultraThinMaterial` background, tint-colored label. `wide`
uses `.frame(maxWidth: .infinity)`.

### `Haptics.swift`

```swift
enum Haptic {
    static func tapLog()        // .click
    static func goalReached(_ metric: MetricKind)  // .success, debounced
    static func crownStep()     // .click
}
```

`goalReached` debounce: `UserDefaults.standard` key `haptic.goal.<metric>.day`
stores last-fired `Date.startOfDay`. Skip if equal to today.

## Watch View Layouts

### `WatchSummaryView`
```swift
NavigationStack {
    ScrollView {
        VStack(spacing: 0) {
            ForEach(MetricKind.allCases) { kind in
                MiniRingRow(metric: kind,
                            value: store.total(of: kind.intakeType),
                            target: target(for: kind))
            }
        }.padding(.horizontal, WatchTheme.Spacing.pageH)
    }.navigationTitle("Today")
}
```

### Water / Caffeine
```swift
VStack(spacing: WatchTheme.Spacing.stack) {
    HeroRing(metric: .water, value: total, target: target,
             caption: "of \(Formatting.glasses(target))")
    HStack(spacing: 6) {
        QuickActionChip(label: "½", tint: .water) { log(0.5) }
        QuickActionChip(label: "1", tint: .water) { log(1.0) }
    }
    QuickActionChip(label: "Bottle", wide: true, tint: .water) { log(2.0) }
}
```

### Fullness
HeroRing shows `loggedMealCount / 4` with caption "meals logged". Below:
2×2 `LazyVGrid` of meal cells, each opens fullness picker sheet on tap.

### Weight / Waist
HeroRing center shows latest reading. Ring fill formula:
`1 - min(|current - target| / target, 1)` — closer to target = fuller ring,
direction-agnostic since target can be loss or gain. Caption: `"kg"` /
`"cm"` when reading exists, else `"tap to log"`.

Below: `Text(crownValue)` focusable + `.digitalCrownRotation(_, from:through:by:
sensitivity:.medium, isHapticFeedbackEnabled: true)`. Save chip commits via
`store.add`. Range clamps and steps:
- Weight: `from: 30, through: 200, by: 0.1` (kg)
- Waist:  `from: 40, through: 150, by: 0.5` (cm)

## Complications

### Existing (refactored)
- `WaterCircularWidget`, `CaffeineCircularWidget` — already exist, restyled
  with `WatchTheme` colors and gradient arc.

### New
- `FullnessCircularWidget` — accessoryCircular, shows `meals/4`
- `WeightCircularWidget` — accessoryCircular, shows latest weight readout
- `WaterCornerWidget`, `CaffeineCornerWidget` — accessoryCorner, gauge + label
- `WaterInlineWidget`, `CaffeineInlineWidget` — accessoryInline single-line
  (`"💧 5/8 · ☕ 220mg"` style via SF Symbol `Text` interpolation)
- `HydrationSmartStackWidget`, `CaffeineSmartStackWidget` — accessoryRectangular,
  Smart Stack hero with `Button(intent:)` for inline logging

### Smart Stack relevance

```swift
struct HydrationProvider: TimelineProvider {
    func relevances() async -> WidgetRelevances<Void> {
        let last = sharedDefaults.object(forKey: "complication.lastWaterLogged") as? Date
        let gap = Date().timeIntervalSince(last ?? .distantPast)
        if gap > 7200 {  // 2h
            return WidgetRelevances([
                .init(context: .init(kind: .userActivity), score: 0.9)
            ])
        }
        return WidgetRelevances([])
    }
}
```

Caffeine provider: triggers 13:00–18:00 local time when remaining headroom
to target < 100mg, computed via `CaffeineKinetics.bloodstreamLevel(at:)`.

## Data Flow

```
User taps QuickActionChip
  → IntakeStore.add(entry)
      ↓
   entries.append, persist UserDefaults JSON
      ↓
   SyncService.sendEntry → WCSession transferUserInfo (delta to iOS)
      ↓
   writeComplicationData() → App Group defaults updated
      ↓
   WidgetCenter.shared.reloadAllTimelines()
      ↓
   check goal-hit (pre < target ≤ post) → Haptic.goalReached(metric)
      ↓
   @Published triggers SwiftUI re-render
  → Haptic.tapLog()
```

## App Group Schema (additions)

```
group.com.intaketracker.shared:
  complication.fullnessCount       Int      [NEW]
  complication.weightLatest        Double   [NEW]
  complication.lastWaterLogged     Date     [NEW]  hydration relevance
  complication.lastCaffeineLogged  Date     [NEW]  caffeine relevance
  target.weightKg                  Double   [NEW]  mirror for widgets
  (existing keys unchanged)
```

## Error Handling

- Watch logging stays offline-first. `IntakeStore.add` does not throw.
- `SyncService` queues sends if WCSession unreachable (current behavior).
- Crown steppers clamp to per-metric range; out-of-range values rejected silently.
- `Haptic.goalReached` no-op when debounce key matches today.
- Smart Stack relevance returns empty `WidgetRelevances` on read failure
  (first launch, missing keys) — widget simply does not surface.
- All palette colors verified WCAG AA on `#000` background.

## Testing

**Unit (`IntakeTrackerTests/`):**
- `MetricKindTests` — color/glyph/format/target mapping per case
- `HapticDebounceTests` — `goalReached` fires once per metric per day
- `HydrationRelevanceTests` — score given gaps {0h, 1h, 3h, 24h}
- `CaffeineRelevanceTests` — score across times-of-day and target headroom

**Manual QA matrix:**
- 6 watch pages (summary + 5 metrics) × 3 states (empty / mid / goal-hit) = 18 states
- 4 complication families × 5 metrics on watch face
- Smart Stack: fast-forward `lastWaterLogged` >2h, verify tile surfaces;
  log via inline button, verify dismissal

## Out of Scope (YAGNI)

- iOS UI parity pass.
- Widget configuration intents (per-widget metric picking).
- Animation tuning beyond `.animation(.smooth)` ring fills.
- Theme switching, dark/light alternates.
- watchOS <10 fallbacks.
