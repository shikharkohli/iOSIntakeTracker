import SwiftUI

struct WatchCaffeineView: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage("target.caffeineMg") private var target: Double = 400
    @AppStorage(CaffeineKinetics.halfLifeKey) private var halfLifeHours: Double = CaffeineKinetics.defaultHalfLifeHours
    @State private var isLogging = false
    @State private var pageIndex: Int = 0

    private var total: Double { store.total(of: .caffeine) }

    private func bodyLoad(at now: Date) -> Double {
        CaffeineKinetics.currentBodyLoad(entries: store.entries, now: now, halfLifeHours: halfLifeHours)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    CaffeineHeroRing(
                        total: total,
                        target: target,
                        inBody: bodyLoad(at: context.date)
                    )
                }
                .frame(height: 100)

                TabView(selection: $pageIndex) {
                    ForEach(Array(CaffeinePreset.presets.enumerated()), id: \.offset) { index, preset in
                        PresetPage(preset: preset) { log(preset) }
                            .tag(index)
                            .padding(.horizontal, 4)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(maxHeight: .infinity)
            }
            .padding(.horizontal, 6)
            .padding(.top, 2)
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

private struct CaffeineHeroRing: View {
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
                .stroke(WatchTheme.Color.caffeine.opacity(0.18), lineWidth: 7)
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(1, fraction))))
                .stroke(
                    LinearGradient(
                        colors: [WatchTheme.Color.caffeine, WatchTheme.Color.caffeine.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(Int(inBody.rounded()))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(WatchTheme.Color.caffeine)
                Text("mg")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("\(Int(total.rounded())) / \(Int(target.rounded()))")
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .padding(.top, 1)
            }
        }
        .frame(width: 92, height: 92)
    }
}

private struct PresetPage: View {
    let preset: CaffeinePreset
    let action: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: preset.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                VStack(alignment: .leading, spacing: 0) {
                    Text(preset.name)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(Int(preset.milligrams)) mg")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Spacer()
            }
            .foregroundStyle(WatchTheme.Color.caffeine)

            Button(action: action) {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Log")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(WatchTheme.Color.caffeine)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WatchTheme.Radius.chip))
                .overlay(
                    RoundedRectangle(cornerRadius: WatchTheme.Radius.chip)
                        .stroke(WatchTheme.Color.caffeine.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}
