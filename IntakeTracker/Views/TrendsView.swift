import SwiftUI
import Charts

enum TrendRange: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }

    var bucketUnit: Calendar.Component {
        switch self {
        case .day: return .hour
        case .week, .month: return .day
        case .year: return .weekOfYear
        }
    }

    var axisStride: Calendar.Component {
        switch self {
        case .day: return .hour
        case .week: return .day
        case .month: return .weekOfYear
        case .year: return .month
        }
    }

    var axisFormat: Date.FormatStyle {
        switch self {
        case .day: return .dateTime.hour()
        case .week: return .dateTime.weekday(.abbreviated)
        case .month: return .dateTime.day().month(.abbreviated)
        case .year: return .dateTime.month(.abbreviated)
        }
    }
}

struct TrendsView: View {
    @EnvironmentObject private var store: IntakeStore
    @State private var range: TrendRange = .week

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Range", selection: $range) {
                        ForEach(TrendRange.allCases) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)

                    WaterTrendCard(range: range)
                    CaffeineTrendCard(range: range)
                    WeightTrendCard(range: range)
                    WaistTrendCard(range: range)
                    FullnessTrendCard(range: range)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Trends")
        }
    }
}

// MARK: - Aggregation helpers

private struct Bucket: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

private func bucketedTotals(entries: [IntakeEntry], type: IntakeType, range: TrendRange) -> [Bucket] {
    let cal = Calendar.current
    let now = Date()
    let startDay = cal.startOfDay(for: now)
    let start: Date
    switch range {
    case .day: start = startDay
    case .week: start = cal.date(byAdding: .day, value: -6, to: startDay) ?? startDay
    case .month: start = cal.date(byAdding: .day, value: -29, to: startDay) ?? startDay
    case .year: start = cal.date(byAdding: .day, value: -364, to: startDay) ?? startDay
    }

    let filtered = entries.filter { $0.type == type && $0.timestamp >= start }
    var buckets: [Date: Double] = [:]
    for entry in filtered {
        let bucket = bucketStart(for: entry.timestamp, unit: range.bucketUnit, cal: cal)
        buckets[bucket, default: 0] += entry.amount
    }
    return buckets
        .sorted { $0.key < $1.key }
        .map { Bucket(date: $0, value: $1) }
}

private func rawPoints(entries: [IntakeEntry], type: IntakeType, range: TrendRange) -> [Bucket] {
    let cal = Calendar.current
    let now = Date()
    let startDay = cal.startOfDay(for: now)
    let start: Date
    switch range {
    case .day: start = startDay
    case .week: start = cal.date(byAdding: .day, value: -6, to: startDay) ?? startDay
    case .month: start = cal.date(byAdding: .day, value: -29, to: startDay) ?? startDay
    case .year: start = cal.date(byAdding: .day, value: -364, to: startDay) ?? startDay
    }
    return entries
        .filter { $0.type == type && $0.timestamp >= start }
        .sorted { $0.timestamp < $1.timestamp }
        .map { Bucket(date: $0.timestamp, value: $0.amount) }
}

private func bucketStart(for date: Date, unit: Calendar.Component, cal: Calendar) -> Date {
    switch unit {
    case .hour:
        var comps = cal.dateComponents([.year, .month, .day, .hour], from: date)
        comps.minute = 0; comps.second = 0
        return cal.date(from: comps) ?? date
    case .weekOfYear:
        return cal.dateInterval(of: .weekOfYear, for: date)?.start ?? cal.startOfDay(for: date)
    default:
        return cal.startOfDay(for: date)
    }
}

// MARK: - Trend cards

private struct TrendCard<Content: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    let subtitle: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage).foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            content()
                .frame(height: 180)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct WaterTrendCard: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage("target.waterGlasses") private var target: Double = 8
    let range: TrendRange

    var body: some View {
        let data = bucketedTotals(entries: store.entries, type: .water, range: range)
        let avg = averagePerDay(data: data, range: range)

        TrendCard(
            title: "Water",
            systemImage: "drop.fill",
            tint: .blue,
            subtitle: "Avg \(Formatting.glasses(avg)) per day"
        ) {
            Chart {
                ForEach(data) { bucket in
                    BarMark(
                        x: .value("Date", bucket.date, unit: range.bucketUnit),
                        y: .value("Glasses", bucket.value)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(3)
                }
                if range != .day {
                    RuleMark(y: .value("Goal", target))
                        .foregroundStyle(.blue.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .annotation(position: .topTrailing, alignment: .trailing) {
                            Text("Goal")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: range.axisStride)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: range.axisFormat)
                }
            }
        }
    }
}

private struct CaffeineTrendCard: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage("target.caffeineMg") private var target: Double = 400
    let range: TrendRange

    var body: some View {
        let data = bucketedTotals(entries: store.entries, type: .caffeine, range: range)
        let avg = averagePerDay(data: data, range: range)

        TrendCard(
            title: "Caffeine",
            systemImage: "cup.and.saucer.fill",
            tint: .brown,
            subtitle: "Avg \(Formatting.mg(avg)) per day"
        ) {
            Chart {
                ForEach(data) { bucket in
                    BarMark(
                        x: .value("Date", bucket.date, unit: range.bucketUnit),
                        y: .value("mg", bucket.value)
                    )
                    .foregroundStyle(Color.brown.gradient)
                    .cornerRadius(3)
                }
                if range != .day {
                    RuleMark(y: .value("Limit", target))
                        .foregroundStyle(.brown.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .annotation(position: .topTrailing, alignment: .trailing) {
                            Text("Limit")
                                .font(.caption2)
                                .foregroundStyle(.brown)
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: range.axisStride)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: range.axisFormat)
                }
            }
        }
    }
}

private struct WeightTrendCard: View {
    @EnvironmentObject private var store: IntakeStore
    let range: TrendRange

    var body: some View {
        let data = rawPoints(entries: store.entries, type: .weight, range: range)
            .map { Bucket(date: $0.date, value: Formatting.display(fromKg: $0.value)) }
        let subtitle: String = {
            if let latestKg = latestAmount(store.entries, .weight) {
                return "Latest \(Formatting.weight(kg: latestKg))"
            }
            return "No readings"
        }()

        TrendCard(title: "Weight", systemImage: "scalemass.fill", tint: .green, subtitle: subtitle) {
            if data.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.value)
                        )
                        .foregroundStyle(.green)
                        .interpolationMethod(.monotone)
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.value)
                        )
                        .foregroundStyle(.green)
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .stride(by: range.axisStride)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: range.axisFormat)
                    }
                }
            }
        }
    }
}

private struct WaistTrendCard: View {
    @EnvironmentObject private var store: IntakeStore
    let range: TrendRange

    var body: some View {
        let data = rawPoints(entries: store.entries, type: .waist, range: range)
            .map { Bucket(date: $0.date, value: Formatting.display(fromCm: $0.value)) }
        let subtitle: String = {
            if let latestCm = latestAmount(store.entries, .waist) {
                return "Latest \(Formatting.waist(cm: latestCm))"
            }
            return "No readings"
        }()

        TrendCard(title: "Waist", systemImage: "ruler.fill", tint: .purple, subtitle: subtitle) {
            if data.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Waist", point.value)
                        )
                        .foregroundStyle(.purple)
                        .interpolationMethod(.monotone)
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Waist", point.value)
                        )
                        .foregroundStyle(.purple)
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .stride(by: range.axisStride)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: range.axisFormat)
                    }
                }
            }
        }
    }
}

private struct FullnessTrendCard: View {
    @EnvironmentObject private var store: IntakeStore
    let range: TrendRange

    var body: some View {
        let data = rawPoints(entries: store.entries, type: .fullness, range: range)
        let avg: Double = data.isEmpty ? 0 : data.map(\.value).reduce(0, +) / Double(data.count)
        let subtitle: String = data.isEmpty ? "No readings" : String(format: "Avg %.1f / 5", avg)

        TrendCard(title: "Fullness", systemImage: "fork.knife", tint: .orange, subtitle: subtitle) {
            if data.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(data) { point in
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Level", point.value)
                        )
                        .foregroundStyle(.orange)
                        .symbolSize(80)
                    }
                }
                .chartYScale(domain: 0.5...5.5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: range.axisStride)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: range.axisFormat)
                    }
                }
            }
        }
    }
}

private var emptyState: some View {
    VStack {
        Spacer()
        Text("No data in this range")
            .font(.footnote)
            .foregroundStyle(.secondary)
        Spacer()
    }
    .frame(maxWidth: .infinity)
}

private func averagePerDay(data: [Bucket], range: TrendRange) -> Double {
    guard !data.isEmpty else { return 0 }
    switch range {
    case .day:
        return data.map(\.value).reduce(0, +)
    case .week, .month, .year:
        let totalDays = max(1, Set(data.map { Calendar.current.startOfDay(for: $0.date) }).count)
        let sum = data.map(\.value).reduce(0, +)
        return sum / Double(totalDays)
    }
}

private func latestAmount(_ entries: [IntakeEntry], _ type: IntakeType) -> Double? {
    entries.first(where: { $0.type == type })?.amount
}
