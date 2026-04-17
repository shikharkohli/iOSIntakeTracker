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
                    WeightCard()
                    WaistCard()
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

// MARK: - Weight

private struct WeightCard: View {
    @EnvironmentObject private var store: IntakeStore
    @State private var showSheet = false

    private var latest: IntakeEntry? { store.latestEntry(type: .weight) }

    var body: some View {
        Card(title: "Weight", systemImage: "scalemass.fill", tint: .green) {
            VStack(alignment: .leading, spacing: 12) {
                if let latest {
                    Text(Formatting.weight(kg: latest.amount))
                        .font(.largeTitle.bold())
                        .monospacedDigit()
                    Text("Last logged \(Formatting.time.string(from: latest.timestamp))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Not logged yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    showSheet = true
                } label: {
                    Label("Log weight", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .sheet(isPresented: $showSheet) {
            WeightSheet(initialKg: latest?.amount ?? 70)
        }
    }
}

private struct WeightSheet: View {
    @EnvironmentObject private var store: IntakeStore
    @Environment(\.dismiss) private var dismiss
    @State private var value: Double
    private let unit: UnitMass
    private let step: Double
    private let range: ClosedRange<Double>

    init(initialKg: Double) {
        let metric = Formatting.usesMetric
        self.unit = metric ? .kilograms : .pounds
        self.step = metric ? 0.1 : 0.2
        self.range = metric ? 20...300 : 44...660
        self._value = State(initialValue: Formatting.display(fromKg: initialKg))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Weight") {
                    Stepper(value: $value, in: range, step: step) {
                        Text(formatted)
                            .font(.title2.bold())
                            .monospacedDigit()
                    }
                    Slider(value: $value, in: range, step: step)
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        store.add(IntakeEntry(type: .weight, amount: Formatting.kg(fromDisplay: value)))
                        dismiss()
                    }
                }
            }
        }
    }

    private var formatted: String {
        let m = Measurement(value: value, unit: unit)
        let f = MeasurementFormatter()
        f.unitOptions = [.providedUnit]
        f.unitStyle = .medium
        f.numberFormatter.maximumFractionDigits = 1
        f.numberFormatter.minimumFractionDigits = 1
        return f.string(from: m)
    }
}

// MARK: - Waist

private struct WaistCard: View {
    @EnvironmentObject private var store: IntakeStore
    @State private var showSheet = false

    private var latest: IntakeEntry? { store.latestEntry(type: .waist) }

    var body: some View {
        Card(title: "Waist", systemImage: "ruler.fill", tint: .purple) {
            VStack(alignment: .leading, spacing: 12) {
                if let latest {
                    Text(Formatting.waist(cm: latest.amount))
                        .font(.largeTitle.bold())
                        .monospacedDigit()
                    Text("Last logged \(Formatting.time.string(from: latest.timestamp))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Not logged yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    showSheet = true
                } label: {
                    Label("Log waist", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
        }
        .sheet(isPresented: $showSheet) {
            WaistSheet(initialCm: latest?.amount ?? 85)
        }
    }
}

private struct WaistSheet: View {
    @EnvironmentObject private var store: IntakeStore
    @Environment(\.dismiss) private var dismiss
    @State private var value: Double
    private let unit: UnitLength
    private let step: Double
    private let range: ClosedRange<Double>

    init(initialCm: Double) {
        let metric = Formatting.usesMetric
        self.unit = metric ? .centimeters : .inches
        self.step = metric ? 0.5 : 0.25
        self.range = metric ? 40...200 : 16...79
        self._value = State(initialValue: Formatting.display(fromCm: initialCm))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Waist circumference") {
                    Stepper(value: $value, in: range, step: step) {
                        Text(formatted)
                            .font(.title2.bold())
                            .monospacedDigit()
                    }
                    Slider(value: $value, in: range, step: step)
                }
            }
            .navigationTitle("Log Waist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        store.add(IntakeEntry(type: .waist, amount: Formatting.cm(fromDisplay: value)))
                        dismiss()
                    }
                }
            }
        }
    }

    private var formatted: String {
        let m = Measurement(value: value, unit: unit)
        let f = MeasurementFormatter()
        f.unitOptions = [.providedUnit]
        f.unitStyle = .medium
        f.numberFormatter.maximumFractionDigits = 1
        f.numberFormatter.minimumFractionDigits = 1
        return f.string(from: m)
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
