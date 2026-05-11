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

    private var shortName: [String: String] {
        ["Coffee": "Coffee", "Espresso": "Espresso", "Tea": "Tea", "Energy Drink": "Energy", "Soda": "Soda"]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    HeroCompactRing(
                        total: total,
                        target: target,
                        inBody: bodyLoad(at: context.date)
                    )
                }

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)],
                    spacing: 4
                ) {
                    ForEach(CaffeinePreset.presets) { preset in
                        presetTile(preset)
                    }
                }
            }
            .padding(.horizontal, 6)
        }
    }

    private func presetTile(_ preset: CaffeinePreset) -> some View {
        Button {
            log(preset)
        } label: {
            VStack(spacing: 1) {
                Image(systemName: preset.systemImage)
                    .font(.system(size: 13, weight: .semibold))
                Text(shortName[preset.name] ?? preset.name)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(Int(preset.milligrams))")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .foregroundStyle(WatchTheme.Color.caffeine)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WatchTheme.Radius.tile))
            .overlay(
                RoundedRectangle(cornerRadius: WatchTheme.Radius.tile)
                    .stroke(WatchTheme.Color.caffeine.opacity(0.3), lineWidth: 0.6)
            )
        }
        .buttonStyle(.plain)
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

private struct HeroCompactRing: View {
    let total: Double
    let target: Double
    let inBody: Double

    private var fraction: Double {
        guard target > 0 else { return 0 }
        return min(total / target, 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(WatchTheme.Color.caffeine.opacity(0.18), lineWidth: 6)
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(1, fraction))))
                .stroke(
                    LinearGradient(
                        colors: [WatchTheme.Color.caffeine, WatchTheme.Color.caffeine.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(Int(inBody.rounded()))")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(WatchTheme.Color.caffeine)
                Text("mg in body")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 78, height: 78)
        .padding(.top, 2)
    }
}
