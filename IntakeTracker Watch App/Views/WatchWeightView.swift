import SwiftUI

struct WatchWeightView: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage("target.weightKg") private var target: Double = 70

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

                NavigationLink {
                    WeightPickerView(initial: latest > 0 ? latest : target)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Log")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(WatchTheme.Color.weight)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WatchTheme.Radius.chip))
                    .overlay(
                        RoundedRectangle(cornerRadius: WatchTheme.Radius.chip)
                            .stroke(WatchTheme.Color.weight.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, WatchTheme.Spacing.pageH)
        }
    }
}

private struct WeightPickerView: View {
    @EnvironmentObject private var store: IntakeStore
    @Environment(\.dismiss) private var dismiss
    let initial: Double
    @State private var value: Double
    @FocusState private var focused: Bool

    init(initial: Double) {
        self.initial = initial
        _value = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: WatchTheme.Spacing.stack) {
            Text(Formatting.weight(kg: value))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(WatchTheme.Color.weight)
                .focusable()
                .focused($focused)
                .digitalCrownRotation(
                    $value,
                    from: 30, through: 200, by: 0.1,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )

            QuickActionChip(label: "Save", glyph: "checkmark.circle.fill", wide: true, tint: WatchTheme.Color.weight) {
                store.add(IntakeEntry(type: .weight, amount: value))
                Haptic.tapLog()
                dismiss()
            }
        }
        .padding(.horizontal, WatchTheme.Spacing.pageH)
        .onAppear { focused = true }
    }
}
