import SwiftUI
import WatchKit

struct WatchWeightView: View {
    @EnvironmentObject private var store: IntakeStore
    @State private var valueKg: Double = 70
    @State private var initialized = false
    @State private var isLogging = false
    @State private var feedbackMessage: String?

    private var step: Double { Formatting.usesMetric ? 0.5 : 0.4536 } // ~1 lb in kg
    private let minKg: Double = 20
    private let maxKg: Double = 300

    var body: some View {
        VStack(spacing: 6) {
            Text("Weight").font(.headline)
            Text(Formatting.weight(kg: valueKg))
                .font(.title3.bold())
                .foregroundStyle(.green)
                .monospacedDigit()

            HStack(spacing: 6) {
                Button {
                    adjust(-step)
                } label: {
                    Image(systemName: "minus")
                        .frame(maxWidth: .infinity)
                }
                Button {
                    adjust(step)
                } label: {
                    Image(systemName: "plus")
                        .frame(maxWidth: .infinity)
                }
            }
            .tint(.green)

            Button {
                guard !isLogging else { return }
                isLogging = true
                store.add(IntakeEntry(type: .weight, amount: valueKg))
                WKInterfaceDevice.current().play(.success)
                feedbackMessage = "Logged"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    feedbackMessage = nil
                    isLogging = false
                }
            } label: {
                Label("Log", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLogging)
            .tint(.green)
            if let feedbackMessage {
                Text(feedbackMessage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 4)
        .onAppear {
            guard !initialized else { return }
            initialized = true
            if let last = store.latestEntry(type: .weight) {
                valueKg = last.amount
            }
        }
    }

    private func adjust(_ delta: Double) {
        valueKg = min(maxKg, max(minKg, valueKg + delta))
        WKInterfaceDevice.current().play(.click)
    }
}
