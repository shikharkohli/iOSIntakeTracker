import SwiftUI

struct WatchFullnessView: View {
    @EnvironmentObject private var store: IntakeStore
    @State private var pickerMeal: MealType?

    private var loggedCount: Int {
        MealType.allCases.reduce(0) { $0 + (store.mealFullness(for: $1) == nil ? 0 : 1) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: WatchTheme.Spacing.stack) {
                HeroRing(
                    metric: .fullness,
                    value: Double(loggedCount),
                    target: Double(MealType.allCases.count),
                    caption: "meals logged",
                    centerOverride: "\(loggedCount)/\(MealType.allCases.count)"
                )

                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 4) {
                    ForEach(MealType.allCases) { meal in
                        Button {
                            pickerMeal = meal
                        } label: {
                            VStack(spacing: 2) {
                                if let entry = store.mealFullness(for: meal),
                                   let level = FullnessLevel(rawValue: Int(entry.amount)) {
                                    Text(level.emoji).font(.title3)
                                } else {
                                    Text(meal.emoji).font(.title3).opacity(0.35)
                                }
                                Text(meal.displayName)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WatchTheme.Radius.tile))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, WatchTheme.Spacing.pageH)
            .sheet(item: $pickerMeal) { meal in
                FullnessPickerSheet(meal: meal)
            }
        }
    }
}

private struct FullnessPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: IntakeStore
    let meal: MealType

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text(meal.displayName).font(.headline)
                ForEach(FullnessLevel.allCases) { level in
                    Button {
                        store.add(IntakeEntry(type: .fullness, amount: Double(level.rawValue), meal: meal))
                        Haptic.tapLog()
                        dismiss()
                    } label: {
                        HStack {
                            Text(level.emoji).font(.title3)
                            Text(level.label).font(.system(size: 13))
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WatchTheme.Radius.tile))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, WatchTheme.Spacing.pageH)
        }
    }
}
