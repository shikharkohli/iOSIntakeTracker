import SwiftUI
import WatchKit

struct WatchCaffeineView: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage("target.caffeineMg") private var target: Double = 400

    private var total: Double { store.total(of: .caffeine) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 6) {
                    Text("Caffeine")
                        .font(.headline)
                    Text(Formatting.mg(total))
                        .font(.title3.bold())
                        .foregroundStyle(.brown)
                    ProgressView(value: min(total, target), total: target)
                        .tint(.brown)
                    Text("of \(Formatting.mg(target))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    ForEach(CaffeinePreset.presets) { preset in
                        Button {
                            store.add(IntakeEntry(type: .caffeine, amount: preset.milligrams, note: preset.name))
                            WKInterfaceDevice.current().play(.click)
                        } label: {
                            HStack {
                                Image(systemName: preset.systemImage)
                                Text(preset.name)
                                Spacer()
                                Text("\(Int(preset.milligrams))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(.brown)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}
