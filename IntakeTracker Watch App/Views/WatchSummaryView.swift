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
