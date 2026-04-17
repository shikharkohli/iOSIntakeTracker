import SwiftUI
import WatchKit

struct WatchFullnessView: View {
    @EnvironmentObject private var store: IntakeStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
                Text("Fullness")
                    .font(.headline)
                if let latest = store.latestFullness(),
                   let level = FullnessLevel(rawValue: Int(latest.amount)) {
                    Text("\(level.emoji) \(level.label)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("After your meal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    ForEach(FullnessLevel.allCases) { level in
                        Button {
                            store.add(IntakeEntry(type: .fullness,
                                                  amount: Double(level.rawValue),
                                                  note: level.label))
                            WKInterfaceDevice.current().play(.success)
                        } label: {
                            VStack(spacing: 0) {
                                Text(level.emoji).font(.title3)
                                Text("\(level.rawValue)").font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .tint(.orange)
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }
}
