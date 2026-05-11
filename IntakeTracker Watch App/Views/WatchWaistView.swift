import SwiftUI

struct WatchWaistView: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage("target.waistCm") private var target: Double = 80

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
                    caption: latest > 0 ? (Formatting.usesMetric ? "cm" : "in") : "tap to log",
                    centerOverride: latest > 0 ? Formatting.waist(cm: latest) : "—"
                )

                NavigationLink {
                    WaistPickerView(initialCm: latest > 0 ? latest : target)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Log")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(WatchTheme.Color.waist)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WatchTheme.Radius.chip))
                    .overlay(
                        RoundedRectangle(cornerRadius: WatchTheme.Radius.chip)
                            .stroke(WatchTheme.Color.waist.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, WatchTheme.Spacing.pageH)
        }
    }
}

private struct WaistPickerView: View {
    @EnvironmentObject private var store: IntakeStore
    @Environment(\.dismiss) private var dismiss
    let initialCm: Double

    @State private var displayValue: Double
    @FocusState private var focused: Bool

    private var unitLabel: String { Formatting.usesMetric ? "cm" : "in" }
    private var crownRange: ClosedRange<Double> { Formatting.usesMetric ? 40...150 : 16...60 }
    private var crownStep: Double { Formatting.usesMetric ? 0.5 : 0.25 }

    init(initialCm: Double) {
        self.initialCm = initialCm
        _displayValue = State(initialValue: Formatting.display(fromCm: initialCm))
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
                .foregroundStyle(WatchTheme.Color.waist)
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

            QuickActionChip(label: "Save", glyph: "checkmark.circle.fill", wide: true, tint: WatchTheme.Color.waist) {
                let cm = Formatting.cm(fromDisplay: displayValue)
                store.add(IntakeEntry(type: .waist, amount: cm))
                Haptic.tapLog()
                dismiss()
            }
        }
        .padding(.horizontal, WatchTheme.Spacing.pageH)
        .onAppear { focused = true }
    }
}
