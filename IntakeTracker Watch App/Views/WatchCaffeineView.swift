import SwiftUI
import WatchKit

struct WatchCaffeineView: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage("target.caffeineMg") private var target: Double = 400
    @AppStorage(CaffeineKinetics.halfLifeKey) private var halfLifeHours: Double = CaffeineKinetics.defaultHalfLifeHours
    @State private var isLogging = false
    @State private var feedbackMessage: String?

    private var total: Double { store.total(of: .caffeine) }
    private var bodyLoad: Double {
        CaffeineKinetics.currentBodyLoad(entries: store.entries, halfLifeHours: halfLifeHours)
    }

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
                    Text("In body: \(Formatting.mg(bodyLoad))")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.brown)
                    if let feedbackMessage {
                        Text(feedbackMessage)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.green)
                    }

                    ForEach(CaffeinePreset.presets) { preset in
                        Button {
                            guard !isLogging else { return }
                            isLogging = true
                            store.add(IntakeEntry(type: .caffeine, amount: preset.milligrams, note: preset.name))
                            WKInterfaceDevice.current().play(.success)
                            feedbackMessage = "Logged \(preset.name)"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                feedbackMessage = nil
                                isLogging = false
                            }
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
                        .disabled(isLogging)
                        .tint(.brown)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}
