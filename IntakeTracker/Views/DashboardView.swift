import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: IntakeStore
    @State private var showSettings = false

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

// MARK: - Water

private struct WaterCard: View {
    @EnvironmentObject private var store: IntakeStore
    @AppStorage("target.waterGlasses") private var target: Double = 8

    private var total: Double { store.total(of: .water) }

    var body: some View {
        Card(title: "Water", systemImage: "drop.fill", tint: .blue) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(Formatting.glasses(total))
                        .font(.largeTitle.bold())
                        .monospacedDigit()
                    Spacer()
                    Text("\(Int(min(total / max(target, 0.01), 1) * 100))%")
                        .font(.subheadline.bold())
                        .monospacedDigit()
                        .foregroundStyle(.blue)
                }

                ProgressView(value: min(total, target), total: target)
                    .tint(.blue)

                Text("Goal: \(Formatting.glasses(target))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

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
                            .tintedFill(.blue)
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
    @AppStorage("target.caffeineMg") private var target: Double = 400
    @AppStorage(CaffeineKinetics.halfLifeKey) private var halfLifeHours: Double = CaffeineKinetics.defaultHalfLifeHours
    @State private var showCustom = false

    private var total: Double { store.total(of: .caffeine) }

    private func bodyLoad(at now: Date) -> Double {
        CaffeineKinetics.currentBodyLoad(entries: store.entries, now: now, halfLifeHours: halfLifeHours)
    }

    var body: some View {
        Card(title: "Caffeine", systemImage: "cup.and.saucer.fill", tint: .brown) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(Formatting.mg(total))
                        .font(.largeTitle.bold())
                        .monospacedDigit()
                    Spacer()
                    Text("\(Int(min(total / max(target, 0.01), 1) * 100))%")
                        .font(.subheadline.bold())
                        .monospacedDigit()
                        .foregroundStyle(.brown)
                }

                ProgressView(value: min(total, target), total: target)
                    .tint(.brown)

                Text("Limit: \(Formatting.mg(target))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TimelineView(.periodic(from: .now, by: 300)) { context in
                    HStack {
                        Text("In body now")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Formatting.mg1(bodyLoad(at: context.date)))
                            .font(.caption.bold())
                            .monospacedDigit()
                            .foregroundStyle(.brown)
                    }
                }
                Text("Estimated using \(String(format: "%.1f", halfLifeHours))h half-life")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                CaffeineDecayChart()
                    .padding(.top, 4)

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
                            .tintedFill(.brown)
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
    @State private var loggingFor: MealType? = nil

    var body: some View {
        Card(title: "Meals", systemImage: "fork.knife", tint: .orange) {
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(MealType.allCases) { meal in
                        MealSlot(meal: meal, entry: store.mealFullness(for: meal)) {
                            loggingFor = meal
                        }
                    }
                }
                Text("Tap a meal to log your fullness  •  1 = still hungry, 5 = stuffed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(item: $loggingFor) { meal in
            MealFullnessSheet(meal: meal)
        }
    }
}

private struct MealSlot: View {
    let meal: MealType
    let entry: IntakeEntry?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                Text(meal.emoji).font(.title2)
                Text(meal.displayName).font(.caption2).fontWeight(.medium)
                if let entry, let level = FullnessLevel(rawValue: Int(entry.amount)) {
                    Text(level.emoji).font(.footnote)
                    Text(level.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("Log")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .tintedFill(.orange)
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct MealFullnessSheet: View {
    @EnvironmentObject private var store: IntakeStore
    @Environment(\.dismiss) private var dismiss
    let meal: MealType

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text(meal.emoji).font(.system(size: 48))
                    Text(meal.displayName).font(.title2.bold())
                }
                .padding(.top, 8)

                VStack(spacing: 8) {
                    ForEach(FullnessLevel.allCases) { level in
                        Button {
                            store.add(IntakeEntry(type: .fullness,
                                                  amount: Double(level.rawValue),
                                                  note: level.label,
                                                  meal: meal))
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Text(level.emoji).font(.title3)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(level.label).font(.subheadline.weight(.medium))
                                    Text("\(level.rawValue) / 5").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .tintedFill(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("How full are you?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
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

// MARK: - Dark-mode-aware tint fill

private struct TintedFill: ViewModifier {
    let color: Color
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content.background(color.opacity(scheme == .dark ? 0.24 : 0.12))
    }
}

private extension View {
    func tintedFill(_ color: Color) -> some View {
        modifier(TintedFill(color: color))
    }
}
