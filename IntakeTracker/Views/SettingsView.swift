import SwiftUI

struct SettingsView: View {
    @AppStorage("target.waterGlasses") private var waterTarget: Double = 8
    @AppStorage("target.caffeineMg") private var caffeineTarget: Double = 400
    @Environment(\.dismiss) private var dismiss

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
                                Text("Caffeine")
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
                    Text("The FDA considers up to 400 mg of caffeine per day safe for most adults. Targets can differ on iPhone and Apple Watch.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
