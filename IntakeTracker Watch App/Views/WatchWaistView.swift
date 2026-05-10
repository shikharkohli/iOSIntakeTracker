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

                QuickActionChip(label: "Save", glyph: "checkmark.circle.fill", wide: true, tint: WatchTheme.Color.waist) {
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
