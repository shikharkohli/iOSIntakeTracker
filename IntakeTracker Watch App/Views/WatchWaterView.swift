import SwiftUI
import WatchKit

struct WatchWaterView: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage("target.waterGlasses") private var target: Double = 8
    @State private var isLogging = false
    @State private var feedbackMessage: String?

    private var total: Double { store.total(of: .water) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Text("Water")
                    .font(.headline)
                Text(Formatting.glasses(total))
                    .font(.title3.bold())
                    .foregroundStyle(.blue)
                ProgressView(value: min(total, target), total: target)
                    .tint(.blue)
                Text("of \(Formatting.glasses(target))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let feedbackMessage {
                    Text(feedbackMessage)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                }

                HStack(spacing: 8) {
                    quickButton(glasses: 0.5, label: "½")
                    quickButton(glasses: 1.0, label: "1")
                }
                quickButton(glasses: 2.0, label: "Bottle", wide: true)
            }
            .padding(.horizontal, 4)
        }
    }

    private func quickButton(glasses: Double, label: String, wide: Bool = false) -> some View {
        Button {
            guard !isLogging else { return }
            isLogging = true
            store.add(IntakeEntry(type: .water, amount: glasses, note: label))
            WKInterfaceDevice.current().play(.success)
            feedbackMessage = "Logged \(label)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                feedbackMessage = nil
                isLogging = false
            }
        } label: {
            Label(label, systemImage: "drop.fill")
                .frame(maxWidth: wide ? .infinity : nil)
        }
        .disabled(isLogging)
        .tint(.blue)
    }
}
