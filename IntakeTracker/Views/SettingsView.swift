import SwiftUI

struct SettingsView: View {
    @AppStorage("target.waterGlasses") private var waterTarget: Double = 8
    @AppStorage("target.caffeineMg") private var caffeineTarget: Double = 400
    @AppStorage("target.weightKg") private var weightTargetKg: Double = 70
    @AppStorage("target.waistCm") private var waistTargetCm: Double = 85
    @AppStorage(MealWindowKeys.breakfastStartMinutes) private var breakfastStartMinutes: Int = MealWindowDefaults.breakfastStart
    @AppStorage(MealWindowKeys.lunchStartMinutes) private var lunchStartMinutes: Int = MealWindowDefaults.lunchStart
    @AppStorage(MealWindowKeys.snackStartMinutes) private var snackStartMinutes: Int = MealWindowDefaults.snackStart
    @AppStorage(MealWindowKeys.dinnerStartMinutes) private var dinnerStartMinutes: Int = MealWindowDefaults.dinnerStart
    @AppStorage(MealWindowKeys.lateNightStartMinutes) private var lateNightStartMinutes: Int = MealWindowDefaults.lateNightStart
    @Environment(\.dismiss) private var dismiss

    // Bindings in display units; storage is always metric
    private var weightTargetBinding: Binding<Double> {
        Binding(
            get: { Formatting.display(fromKg: weightTargetKg) },
            set: { weightTargetKg = Formatting.kg(fromDisplay: $0) }
        )
    }

    private var waistTargetBinding: Binding<Double> {
        Binding(
            get: { Formatting.display(fromCm: waistTargetCm) },
            set: { waistTargetCm = Formatting.cm(fromDisplay: $0) }
        )
    }

    private var weightRange: ClosedRange<Double> { Formatting.usesMetric ? 20...300 : 44...660 }
    private var weightStep: Double { Formatting.usesMetric ? 0.5 : 1.0 }
    private var waistRange: ClosedRange<Double> { Formatting.usesMetric ? 40...200 : 16...79 }
    private var waistStep: Double { Formatting.usesMetric ? 0.5 : 0.25 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $waterTarget, in: 1...20, step: 0.5) {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            VStack(alignment: .leading) {
                                Text("Water")
                                    .font(.subheadline)
                                Text(Formatting.glasses(waterTarget))
                                    .font(.title3.bold())
                                    .monospacedDigit()
                            }
                        }
                    }

                    Stepper(value: $caffeineTarget, in: 50...1000, step: 10) {
                        HStack {
                            Image(systemName: "cup.and.saucer.fill")
                                .foregroundStyle(.brown)
                                .frame(width: 24)
                            VStack(alignment: .leading) {
                                Text("Caffeine limit")
                                    .font(.subheadline)
                                Text(Formatting.mg(caffeineTarget))
                                    .font(.title3.bold())
                                    .monospacedDigit()
                            }
                        }
                    }
                } header: {
                    Text("Daily Targets")
                } footer: {
                    Text("The FDA considers up to 400 mg of caffeine per day safe for most adults.")
                }

                Section {
                    Stepper(value: weightTargetBinding, in: weightRange, step: weightStep) {
                        HStack {
                            Image(systemName: "scalemass.fill")
                                .foregroundStyle(.green)
                                .frame(width: 24)
                            VStack(alignment: .leading) {
                                Text("Goal weight")
                                    .font(.subheadline)
                                Text(Formatting.weight(kg: weightTargetKg))
                                    .font(.title3.bold())
                                    .monospacedDigit()
                            }
                        }
                    }

                    Stepper(value: waistTargetBinding, in: waistRange, step: waistStep) {
                        HStack {
                            Image(systemName: "ruler.fill")
                                .foregroundStyle(.purple)
                                .frame(width: 24)
                            VStack(alignment: .leading) {
                                Text("Goal waist")
                                    .font(.subheadline)
                                Text(Formatting.waist(cm: waistTargetCm))
                                    .font(.title3.bold())
                                    .monospacedDigit()
                            }
                        }
                    }
                } header: {
                    Text("Body Composition Goals")
                } footer: {
                    Text("Goals are used as reference lines in Trends charts. Targets sync to Apple Watch automatically.")
                }

                Section("Meal Auto-Select Windows") {
                    Stepper(value: $breakfastStartMinutes, in: 0...(23 * 60), step: 30) {
                        LabeledContent("Breakfast starts", value: minuteLabel(breakfastStartMinutes))
                    }
                    Stepper(value: $lunchStartMinutes, in: 0...(23 * 60), step: 30) {
                        LabeledContent("Lunch starts", value: minuteLabel(lunchStartMinutes))
                    }
                    Stepper(value: $snackStartMinutes, in: 0...(23 * 60), step: 30) {
                        LabeledContent("Snack starts", value: minuteLabel(snackStartMinutes))
                    }
                    Stepper(value: $dinnerStartMinutes, in: 0...(23 * 60), step: 30) {
                        LabeledContent("Dinner starts", value: minuteLabel(dinnerStartMinutes))
                    }
                    Stepper(value: $lateNightStartMinutes, in: 0...(23 * 60), step: 30) {
                        LabeledContent("Late night starts", value: minuteLabel(lateNightStartMinutes))
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: waterTarget) { syncTargets() }
            .onChange(of: caffeineTarget) { syncTargets() }
            .onChange(of: weightTargetKg) { syncTargets() }
            .onChange(of: waistTargetCm) { syncTargets() }
            .onChange(of: breakfastStartMinutes) { syncTargets() }
            .onChange(of: lunchStartMinutes) { syncTargets() }
            .onChange(of: snackStartMinutes) { syncTargets() }
            .onChange(of: dinnerStartMinutes) { syncTargets() }
            .onChange(of: lateNightStartMinutes) { syncTargets() }
        }
    }

    private func minuteLabel(_ minutes: Int) -> String {
        let h = ((minutes / 60) % 24 + 24) % 24
        let m = abs(minutes % 60)
        return String(format: "%02d:%02d", h, m)
    }

    private func syncTargets() {
        SyncService.shared.sendTargets(
            water: waterTarget,
            caffeine: caffeineTarget,
            weightKg: weightTargetKg,
            waistCm: waistTargetCm,
            breakfastStartMinutes: breakfastStartMinutes,
            lunchStartMinutes: lunchStartMinutes,
            snackStartMinutes: snackStartMinutes,
            dinnerStartMinutes: dinnerStartMinutes,
            lateNightStartMinutes: lateNightStartMinutes
        )
        // Refresh the complication data so the gauge goal lines update immediately
        IntakeStore.shared.writeComplicationData()
    }
}
