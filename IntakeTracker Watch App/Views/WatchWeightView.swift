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
