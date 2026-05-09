import SwiftUI
import Charts

struct WatchSummaryView: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage("target.waterGlasses") private var waterTarget: Double = 8
    @AppStorage("target.caffeineMg") private var caffeineTarget: Double = 400

    var body: some View {
        NavigationStack {
            // No ScrollView — crown stays with the TabView for page switching
            VStack(alignment: .leading, spacing: 6) {
                WatchProgressBar(
                    label: "Water",
                    systemImage: "drop.fill",
                    value: store.total(of: .water),
                    target: waterTarget,
                    color: .blue,
                    formatValue: { Formatting.glasses($0) }
                )

                WatchProgressBar(
                    label: "Caffeine",
                    systemImage: "cup.and.saucer.fill",
                    value: store.total(of: .caffeine),
                    target: caffeineTarget,
                    color: .brown,
                    formatValue: { Formatting.mg($0) }
                )

                Divider()

                Text("Meals")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                // 2-column meal status grid
                HStack(spacing: 4) {
                    ForEach(MealType.allCases) { meal in
                        VStack(spacing: 2) {
                            if let entry = store.mealFullness(for: meal),
                               let level = FullnessLevel(rawValue: Int(entry.amount)) {
                                Text(level.emoji).font(.body)
                            } else {
                                Text(meal.emoji).font(.body).opacity(0.35)
                            }
                            Text(meal.displayName)
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 6)
            .navigationTitle("Today")
        }
    }
}

// MARK: - Progress bar

struct WatchProgressBar: View {
    let label: String
    let systemImage: String
    let value: Double
    let target: Double
    let color: Color
    let formatValue: (Double) -> String

    private var progress: Double { min(value / max(target, 0.01), 1.0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatValue(value))
                    .font(.caption2.bold())
                    .foregroundStyle(color)
                    .monospacedDigit()
            }
            ProgressView(value: progress)
                .tint(color)
        }
    }
}
