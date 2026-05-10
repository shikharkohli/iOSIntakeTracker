import SwiftUI

struct MiniRingRow: View {
    let metric: MetricKind
    let value: Double
    let target: Double
    var onTap: (() -> Void)? = nil

    private var fraction: Double {
        guard target > 0 else { return 0 }
        return min(value / target, 1.0)
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(WatchTheme.Color.track, lineWidth: WatchTheme.Stroke.miniRing)
                    Circle()
                        .trim(from: 0, to: CGFloat(fraction))
                        .stroke(metric.color, style: StrokeStyle(lineWidth: WatchTheme.Stroke.miniRing, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 22, height: 22)

                Text(metric.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(metric.format(value))
                    .font(.system(size: 13, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(metric.color)
            }
            .padding(.vertical, 6)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5)
            }
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}

#Preview {
    VStack(spacing: 0) {
        MiniRingRow(metric: .water, value: 5, target: 8)
        MiniRingRow(metric: .caffeine, value: 220, target: 400)
    }
    .padding()
    .background(.black)
}
