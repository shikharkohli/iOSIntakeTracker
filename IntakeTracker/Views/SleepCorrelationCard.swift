import SwiftUI
import Charts

struct SleepCorrelationCard: View {
    @EnvironmentObject private var store: IntakeStore
    @StateObject private var health = HealthKitService.shared

    /// Hours past which caffeine is considered "afternoon": noon onwards.
    private let afternoonStartHour = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: "bed.double.fill").foregroundStyle(.indigo)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Caffeine vs. Sleep").font(.headline)
                    Text("Afternoon caffeine vs. that night's sleep")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            content
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .task {
            if health.status == .authorized {
                await health.refresh()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch health.status {
        case .unavailable:
            unavailableState
        case .undetermined, .denied:
            permissionState
        case .authorized:
            authorizedContent
        }
    }

    private var unavailableState: some View {
        Text("Health data isn't available on this device.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 120)
    }

    private var permissionState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Connect to Apple Health to compare your caffeine intake against the sleep your watch records each night.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Button {
                Task { await health.requestAuthorization() }
            } label: {
                Label("Allow Health access", systemImage: "heart.text.square.fill")
                    .frame(maxWidth: .infinity, minHeight: 38)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            if health.status == .denied {
                Text("Access was denied. Enable in Settings → Privacy → Health → IntakeTracker.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var authorizedContent: some View {
        let pairs = computePairs()

        return VStack(alignment: .leading, spacing: 12) {
            if pairs.count < 7 {
                Text("\(pairs.count) night\(pairs.count == 1 ? "" : "s") tracked. Need at least 7 to spot patterns reliably.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if !pairs.isEmpty { miniChart(pairs: pairs) }
            } else {
                if let r = pearson(pairs) {
                    Text(summary(r: r))
                        .font(.callout)
                }
                chart(pairs: pairs)
                    .frame(height: 220)
                Text("\(pairs.count) nights · last 90 days")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func chart(pairs: [Pair]) -> some View {
        Chart {
            ForEach(pairs) { pair in
                PointMark(
                    x: .value("Afternoon caffeine (mg)", pair.afternoonCaffeineMg),
                    y: .value("Sleep (hours)", pair.hoursAsleep)
                )
                .foregroundStyle(.indigo)
                .symbolSize(60)
            }
            if let line = trendLine(pairs: pairs) {
                ForEach([line.start, line.end], id: \.x) { point in
                    LineMark(
                        x: .value("Afternoon caffeine (mg)", point.x),
                        y: .value("Sleep (hours)", point.y),
                        series: .value("Series", "trend")
                    )
                    .foregroundStyle(.indigo.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))
                }
            }
        }
        .chartXAxisLabel("Afternoon caffeine (mg)")
        .chartYAxisLabel("Sleep (hours)")
    }

    private func miniChart(pairs: [Pair]) -> some View {
        Chart {
            ForEach(pairs) { pair in
                PointMark(
                    x: .value("mg", pair.afternoonCaffeineMg),
                    y: .value("hrs", pair.hoursAsleep)
                )
                .foregroundStyle(.indigo)
            }
        }
        .frame(height: 120)
    }

    // MARK: - Computation

    private struct Pair: Identifiable {
        var id: Date { nightOf }
        let nightOf: Date
        let afternoonCaffeineMg: Double
        let hoursAsleep: Double
    }

    private func computePairs() -> [Pair] {
        let calendar = Calendar.current
        return health.sessions.compactMap { session in
            let dayStart = calendar.date(bySettingHour: afternoonStartHour, minute: 0, second: 0, of: session.nightOf) ?? session.nightOf
            let dayEnd = session.wakeDate
            let mg = store.entries
                .filter { $0.type == .caffeine && $0.timestamp >= dayStart && $0.timestamp < dayEnd }
                .reduce(0.0) { $0 + $1.amount }
            return Pair(nightOf: session.nightOf, afternoonCaffeineMg: mg, hoursAsleep: session.hoursAsleep)
        }
    }

    private func pearson(_ pairs: [Pair]) -> Double? {
        guard pairs.count > 1 else { return nil }
        let xs = pairs.map(\.afternoonCaffeineMg)
        let ys = pairs.map(\.hoursAsleep)
        let n = Double(pairs.count)
        let meanX = xs.reduce(0, +) / n
        let meanY = ys.reduce(0, +) / n
        let dxs = xs.map { $0 - meanX }
        let dys = ys.map { $0 - meanY }
        let num = zip(dxs, dys).map(*).reduce(0, +)
        let den = sqrt(dxs.map { $0 * $0 }.reduce(0, +) * dys.map { $0 * $0 }.reduce(0, +))
        guard den > 0 else { return nil }
        return num / den
    }

    private struct TrendLine {
        let start: (x: Double, y: Double)
        let end: (x: Double, y: Double)
    }

    private func trendLine(pairs: [Pair]) -> TrendLine? {
        guard pairs.count > 1 else { return nil }
        let xs = pairs.map(\.afternoonCaffeineMg)
        let ys = pairs.map(\.hoursAsleep)
        let n = Double(pairs.count)
        let meanX = xs.reduce(0, +) / n
        let meanY = ys.reduce(0, +) / n
        let dxs = xs.map { $0 - meanX }
        let dys = ys.map { $0 - meanY }
        let num = zip(dxs, dys).map(*).reduce(0, +)
        let den = dxs.map { $0 * $0 }.reduce(0, +)
        guard den > 0 else { return nil }
        let slope = num / den
        let intercept = meanY - slope * meanX
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 0
        guard minX != maxX else { return nil }
        return TrendLine(
            start: (x: minX, y: intercept + slope * minX),
            end: (x: maxX, y: intercept + slope * maxX)
        )
    }

    private func summary(r: Double) -> String {
        if r <= -0.5 {
            return "Strong link: more afternoon caffeine, noticeably less sleep. Consider an earlier cutoff."
        } else if r <= -0.3 {
            return "Mild link: afternoon caffeine seems to shorten your sleep."
        } else if r >= 0.3 {
            return "Your data shows more sleep on higher-caffeine days — likely noise rather than a real effect."
        } else {
            return "No strong correlation in your data. Caffeine timing isn't an obvious sleep disrupter for you."
        }
    }
}
