import SwiftUI
import WatchKit

struct WatchFullnessView: View {
    @EnvironmentObject private var store: IntakeStore

    var body: some View {
        NavigationStack {
            // VStack instead of List — crown stays with the TabView
            VStack(spacing: 4) {
                ForEach(MealType.allCases) { meal in
                    NavigationLink {
                        MealFullnessPickerView(meal: meal)
                    } label: {
                        HStack(spacing: 8) {
                            Text(meal.emoji).font(.title3)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(meal.displayName)
                                    .font(.footnote.weight(.medium))
                                if let entry = store.mealFullness(for: meal),
                                   let level = FullnessLevel(rawValue: Int(entry.amount)) {
                                    Text("\(level.emoji) \(level.label)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Not logged")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 8)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .navigationTitle("Meals")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct MealFullnessPickerView: View {
    @EnvironmentObject private var store: IntakeStore
    @Environment(\.dismiss) private var dismiss
    let meal: MealType

    var body: some View {
        // ScrollView is fine inside a detail view — crown scrolling here is expected
        ScrollView {
            VStack(spacing: 6) {
                Text(meal.displayName)
                    .font(.headline)

                ForEach(FullnessLevel.allCases) { level in
                    Button {
                        store.add(IntakeEntry(type: .fullness,
                                              amount: Double(level.rawValue),
                                              note: level.label,
                                              meal: meal))
                        WKInterfaceDevice.current().play(.success)
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Text(level.emoji)
                            Text(level.label)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(level.rawValue)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.orange)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle(meal.emoji)
        .navigationBarTitleDisplayMode(.inline)
    }
}
