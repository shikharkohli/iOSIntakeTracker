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
