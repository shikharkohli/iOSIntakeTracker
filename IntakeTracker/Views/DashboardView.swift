import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: IntakeStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    WaterCard()
                    CaffeineCard()
                    FullnessCard()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
        }
    }
}

// MARK: - Water

private struct WaterCard: View {
    @EnvironmentObject private var store: IntakeStore

    var body: some View {
        Card(title: "Water", systemImage: "drop.fill", tint: .blue) {
            VStack(alignment: .leading, spacing: 12) {
                Text(Formatting.glasses(store.total(of: .water)))
                    .font(.largeTitle.bold())
                    .monospacedDigit()

                HStack {
                    ForEach(WaterPreset.presets) { preset in
                        Button {
                            store.add(IntakeEntry(type: .water, amount: preset.glasses, note: preset.name))
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: preset.systemImage)
                                    .font(.title3)
                                Text(preset.name)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(Color.blue.opacity(0.12))
                            .foregroundStyle(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Caffeine

private struct CaffeineCard: View {
    @EnvironmentObject private var store: IntakeStore
    @State private var showCustom = false

    var body: some View {
        Card(title: "Caffeine", systemImage: "cup.and.saucer.fill", tint: .brown) {
            VStack(alignment: .leading, spacing: 12) {
                Text(Formatting.mg(store.total(of: .caffeine)))
                    .font(.largeTitle.bold())
                    .monospacedDigit()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(CaffeinePreset.presets) { preset in
                        Button {
                            store.add(IntakeEntry(type: .caffeine, amount: preset.milligrams, note: preset.name))
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: preset.systemImage)
                                    .font(.title3)
                                Text(preset.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Text("\(Int(preset.milligrams)) mg")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 70)
                            .background(Color.brown.opacity(0.12))
                            .foregroundStyle(.brown)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    showCustom = true
                } label: {
                    Label("Custom amount", systemImage: "slider.horizontal.3")
                        .font(.footnote)
                }
                .buttonStyle(.bordered)
            }
        }
        .sheet(isPresented: $showCustom) {
            CustomCaffeineSheet()
        }
    }
}

private struct CustomCaffeineSheet: View {
    @EnvironmentObject private var store: IntakeStore
    @Environment(\.dismiss) private var dismiss
    @State private var mg: Double = 50
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    Stepper(value: $mg, in: 5...500, step: 5) {
                        Text("\(Int(mg)) mg")
                    }
                    Slider(value: $mg, in: 5...500, step: 5)
                }
                Section("Note") {
                    TextField("e.g. Cold brew", text: $note)
                }
            }
            .navigationTitle("Custom Caffeine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        let n = note.trimmingCharacters(in: .whitespaces)
                        store.add(IntakeEntry(type: .caffeine, amount: mg, note: n.isEmpty ? nil : n))
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Fullness

private struct FullnessCard: View {
    @EnvironmentObject private var store: IntakeStore

    private var latest: IntakeEntry? { store.latestFullness() }

    var body: some View {
        Card(title: "Fullness", systemImage: "fork.knife", tint: .orange) {
            VStack(alignment: .leading, spacing: 12) {
                if let latest, let level = FullnessLevel(rawValue: Int(latest.amount)) {
                    HStack(spacing: 8) {
                        Text(level.emoji).font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text(level.label).font(.headline)
                            Text("Logged \(Formatting.time.string(from: latest.timestamp))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Not logged today")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    ForEach(FullnessLevel.allCases) { level in
                        Button {
                            store.add(IntakeEntry(type: .fullness, amount: Double(level.rawValue), note: level.label))
                        } label: {
                            VStack(spacing: 2) {
                                Text(level.emoji).font(.title2)
                                Text("\(level.rawValue)").font(.caption2.bold())
                            }
                            .frame(maxWidth: .infinity, minHeight: 58)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("1 = still hungry • 5 = stuffed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Card

private struct Card<Content: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            content()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
