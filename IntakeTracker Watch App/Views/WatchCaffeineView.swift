import SwiftUI

struct WatchCaffeineView: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage("target.caffeineMg") private var target: Double = 400
    @AppStorage(CaffeineKinetics.halfLifeKey) private var halfLifeHours: Double = CaffeineKinetics.defaultHalfLifeHours
    @State private var isLogging = false

    private var total: Double { store.total(of: .caffeine) }

    private func bodyLoad(at now: Date) -> Double {
        CaffeineKinetics.currentBodyLoad(entries: store.entries, now: now, halfLifeHours: halfLifeHours)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: WatchTheme.Spacing.stack) {
                    HeroRing(
                        metric: .caffeine,
                        value: total,
                        target: target,
                        caption: "of \(Formatting.mg(target))"
                    )

                    TimelineView(.periodic(from: .now, by: 300)) { context in
                        Text("In body: \(Formatting.mg1(bodyLoad(at: context.date)))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(WatchTheme.Color.caffeine)
                    }

                    VStack(spacing: WatchTheme.Spacing.chipGap) {
                        ForEach(CaffeinePreset.presets) { preset in
                            QuickActionChip(
                                label: "\(preset.name) · \(Int(preset.milligrams))mg",
                                glyph: preset.systemImage,
                                wide: true,
                                tint: WatchTheme.Color.caffeine
                            ) {
                                log(preset)
                            }
                        }
                    }
                }
                .padding(.horizontal, WatchTheme.Spacing.pageH)
            }
        }
    }

    private func log(_ preset: CaffeinePreset) {
        guard !isLogging else { return }
        isLogging = true
        let pre = total
        store.add(IntakeEntry(type: .caffeine, amount: preset.milligrams, note: preset.name))
        Haptic.tapLog()
        if pre < target, total >= target {
            Haptic.goalReached(.caffeine)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isLogging = false }
    }
}
