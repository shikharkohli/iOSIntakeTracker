import SwiftUI

struct HeroRing: View {
    let metric: MetricKind
    let value: Double
    let target: Double
    var caption: String?
    var centerOverride: String? = nil

    private var fraction: Double {
        guard target > 0 else { return 0 }
        return min(value / target, 1.0)
    }

    private var centerText: String {
        if let centerOverride { return centerOverride }
        return metric.format(value)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(WatchTheme.Color.track, style: StrokeStyle(lineWidth: WatchTheme.Stroke.heroRing, lineCap: .round))
            Circle()
                .trim(from: 0, to: CGFloat(fraction))
                .stroke(
                    LinearGradient(
                        colors: [metric.color, metric.color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: WatchTheme.Stroke.heroRing, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.smooth, value: fraction)

            VStack(spacing: 2) {
                Text(centerText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(metric.color)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                if let caption {
                    Text(caption)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 130, height: 130)
    }
}

#Preview {
    HeroRing(metric: .water, value: 5, target: 8, caption: "of 8 cups")
}
