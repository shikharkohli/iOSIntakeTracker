import SwiftUI
import Charts

struct CaffeineDecayChart: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage(CaffeineKinetics.halfLifeKey) private var halfLifeHours: Double = CaffeineKinetics.defaultHalfLifeHours
    @State private var selectedDate: Date?

    private let stepMinutes = 15
    private let startHour = 6
    private let cutoffHour = 18

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let samples = buildSamples(now: context.date)
            let domainStart = startOfDay().addingTimeInterval(TimeInterval(startHour * 3600))
            let domainEnd = startOfDay().addingTimeInterval(24 * 3600)
            let cutoff = startOfDay().addingTimeInterval(TimeInterval(cutoffHour * 3600))
            let peak = max(samples.map(\.mg).max() ?? 0, 1)

            Chart {
                ForEach(samples) { s in
                    AreaMark(
                        x: .value("Time", s.time),
                        y: .value("mg", s.mg)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.brown.opacity(0.45), .brown.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Time", s.time),
                        y: .value("mg", s.mg)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(.brown)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                RectangleMark(
                    xStart: .value("Cutoff start", cutoff),
                    xEnd: .value("Cutoff end", domainEnd)
                )
                .foregroundStyle(.red.opacity(0.08))

                RuleMark(x: .value("Cutoff", cutoff))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(.red.opacity(0.6))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Sleep cutoff")
                            .font(.caption2)
                            .foregroundStyle(.red.opacity(0.8))
                    }

                if let selectedDate, let sample = nearest(samples, to: selectedDate) {
                    RuleMark(x: .value("Selected", sample.time))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .foregroundStyle(.secondary)
                        .annotation(position: .top, alignment: .center, spacing: 4) {
                            VStack(spacing: 2) {
                                Text(Formatting.time.string(from: sample.time))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(Formatting.mg1(sample.mg))
                                    .font(.caption.bold())
                                    .monospacedDigit()
                                    .foregroundStyle(.brown)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
                        }
                }
            }
            .chartXScale(domain: domainStart...domainEnd)
            .chartYScale(domain: 0...(peak * 1.1))
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.hour())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXSelection(value: $selectedDate)
            .frame(height: 160)
        }
    }

    private struct Sample: Identifiable {
        let time: Date
        let mg: Double
        var id: TimeInterval { time.timeIntervalSince1970 }
    }

    private func startOfDay() -> Date {
        Calendar.current.startOfDay(for: Date())
    }

    private func buildSamples(now: Date) -> [Sample] {
        let base = startOfDay()
        let startSeconds = startHour * 3600
        let endSeconds = 24 * 3600
        let step = stepMinutes * 60
        var result: [Sample] = []
        result.reserveCapacity((endSeconds - startSeconds) / step + 1)
        for s in stride(from: startSeconds, through: endSeconds, by: step) {
            let t = base.addingTimeInterval(TimeInterval(s))
            let mg = CaffeineKinetics.currentBodyLoad(
                entries: store.entries,
                now: t,
                halfLifeHours: halfLifeHours
            )
            result.append(Sample(time: t, mg: mg))
        }
        return result
    }

    private func nearest(_ samples: [Sample], to date: Date) -> Sample? {
        samples.min(by: { abs($0.time.timeIntervalSince(date)) < abs($1.time.timeIntervalSince(date)) })
    }
}
