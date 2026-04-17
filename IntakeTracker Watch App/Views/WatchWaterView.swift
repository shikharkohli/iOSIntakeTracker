import SwiftUI
import WatchKit

struct WatchWaterView: View {
    @EnvironmentObject private var store: IntakeStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                Text("Water")
                    .font(.headline)
                Text(Formatting.glasses(store.total(of: .water)))
                    .font(.title3.bold())
                    .foregroundStyle(.blue)

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
            store.add(IntakeEntry(type: .water, amount: glasses, note: label))
            WKInterfaceDevice.current().play(.click)
        } label: {
            Label(label, systemImage: "drop.fill")
                .frame(maxWidth: wide ? .infinity : nil)
        }
        .tint(.blue)
    }
}
