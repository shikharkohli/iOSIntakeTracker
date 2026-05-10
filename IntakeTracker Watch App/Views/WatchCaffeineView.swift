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
