import SwiftUI
import WatchKit

struct WatchCaffeineView: View {
    @EnvironmentObject private var store: IntakeStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    Text("Caffeine")
                        .font(.headline)
                    Text(Formatting.mg(store.total(of: .caffeine)))
                        .font(.title3.bold())
                        .foregroundStyle(.brown)

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
