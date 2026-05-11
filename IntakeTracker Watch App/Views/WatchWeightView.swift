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
                    caption: latest > 0 ? (Formatting.usesMetric ? "kg" : "lb") : "tap to log",
                    centerOverride: latest > 0 ? Formatting.weight(kg: latest) : "—"
                )

                NavigationLink {
                    WeightPickerView(initialKg: latest > 0 ? latest : target)
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
    let initialKg: Double

    @State private var displayValue: Double
    @FocusState private var focused: Bool

    private var unitLabel: String { Formatting.usesMetric ? "kg" : "lb" }
    private var crownRange: ClosedRange<Double> { Formatting.usesMetric ? 30...200 : 66...440 }
    private var crownStep: Double { Formatting.usesMetric ? 0.1 : 0.2 }

    init(initialKg: Double) {
        self.initialKg = initialKg
        _displayValue = State(initialValue: Formatting.display(fromKg: initialKg))
    }

    var body: some View {
        VStack(spacing: WatchTheme.Spacing.stack) {
            TextFieldLink(prompt: Text("Enter \(unitLabel)")) {
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", displayValue))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(unitLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(WatchTheme.Color.weight)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WatchTheme.Radius.chip))
            } onSubmit: { text in
                if let v = Double(text.replacingOccurrences(of: ",", with: ".")) {
                    displayValue = max(crownRange.lowerBound, min(crownRange.upperBound, v))
                }
            }
            .focusable()
            .focused($focused)
            .digitalCrownRotation(
                $displayValue,
                from: crownRange.lowerBound,
                through: crownRange.upperBound,
                by: crownStep,
                sensitivity: .medium,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )

            QuickActionChip(label: "Save", glyph: "checkmark.circle.fill", wide: true, tint: WatchTheme.Color.weight) {
                let kg = Formatting.kg(fromDisplay: displayValue)
                store.add(IntakeEntry(type: .weight, amount: kg))
                Haptic.tapLog()
                dismiss()
            }
        }
        .padding(.horizontal, WatchTheme.Spacing.pageH)
        .onAppear { focused = true }
    }
}
