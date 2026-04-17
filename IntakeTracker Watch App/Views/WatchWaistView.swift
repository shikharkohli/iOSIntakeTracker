import SwiftUI
import WatchKit

struct WatchWaistView: View {
    @EnvironmentObject private var store: IntakeStore
    @State private var valueCm: Double = 85
    @State private var initialized = false

    private var step: Double { Formatting.usesMetric ? 0.5 : 1.27 } // ~0.5 in in cm
    private let minCm: Double = 40
    private let maxCm: Double = 200

    var body: some View {
        VStack(spacing: 6) {
            Text("Waist").font(.headline)
            Text(Formatting.waist(cm: valueCm))
                .font(.title3.bold())
                .foregroundStyle(.purple)
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
            .tint(.purple)

            Button {
                store.add(IntakeEntry(type: .waist, amount: valueCm))
                WKInterfaceDevice.current().play(.success)
            } label: {
                Label("Log", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding(.horizontal, 4)
        .onAppear {
            guard !initialized else { return }
            initialized = true
            if let last = store.latestEntry(type: .waist) {
                valueCm = last.amount
            }
        }
    }

    private func adjust(_ delta: Double) {
        valueCm = min(maxCm, max(minCm, valueCm + delta))
        WKInterfaceDevice.current().play(.click)
    }
}
