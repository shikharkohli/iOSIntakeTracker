import Foundation
import AppIntents
import WidgetKit

enum WaterAmountPreset: String, AppEnum {
    case halfGlass
    case oneGlass
    case bottle

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Water Amount")
    static var caseDisplayRepresentations: [WaterAmountPreset: DisplayRepresentation] = [
        .halfGlass: DisplayRepresentation(title: "1/2 Glass"),
        .oneGlass: DisplayRepresentation(title: "1 Glass"),
        .bottle: DisplayRepresentation(title: "Bottle")
    ]

    var glasses: Double {
        switch self {
        case .halfGlass: return 0.5
        case .oneGlass: return 1.0
        case .bottle: return 2.0
        }
    }
}

enum CaffeineAmountPreset: String, AppEnum {
    case coffee
    case espresso
    case tea
    case energyDrink
    case soda

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Caffeine Amount")
    static var caseDisplayRepresentations: [CaffeineAmountPreset: DisplayRepresentation] = [
        .coffee: DisplayRepresentation(title: "Coffee (95 mg)"),
        .espresso: DisplayRepresentation(title: "Espresso (63 mg)"),
        .tea: DisplayRepresentation(title: "Tea (40 mg)"),
        .energyDrink: DisplayRepresentation(title: "Energy Drink (160 mg)"),
        .soda: DisplayRepresentation(title: "Soda (35 mg)")
    ]

    var mg: Double {
        switch self {
        case .coffee: return 95
        case .espresso: return 63
        case .tea: return 40
        case .energyDrink: return 160
        case .soda: return 35
        }
    }

    var note: String {
        switch self {
        case .coffee: return "Coffee"
        case .espresso: return "Espresso"
        case .tea: return "Tea"
        case .energyDrink: return "Energy Drink"
        case .soda: return "Soda"
        }
    }
}

enum FullnessLevelPreset: Int, AppEnum {
    case stillHungry = 1
    case slightlyHungry = 2
    case satisfied = 3
    case full = 4
    case stuffed = 5

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Fullness")
    static var caseDisplayRepresentations: [FullnessLevelPreset: DisplayRepresentation] = [
        .stillHungry: DisplayRepresentation(title: "Still hungry"),
        .slightlyHungry: DisplayRepresentation(title: "Slightly hungry"),
        .satisfied: DisplayRepresentation(title: "Satisfied"),
        .full: DisplayRepresentation(title: "Full"),
        .stuffed: DisplayRepresentation(title: "Stuffed")
    ]

    var note: String {
        FullnessLevel(rawValue: rawValue)?.label ?? "Fullness"
    }
}

struct LogWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Water"

    @Parameter(title: "Amount")
    var quantity: WaterAmountPreset

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            IntakeStore.shared.add(
                IntakeEntry(type: .water, amount: quantity.glasses, note: quantity.rawValue),
                broadcast: true
            )
            WidgetCenter.shared.reloadAllTimelines()
        }
        return .result()
    }
}

struct LogCaffeineIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Caffeine"

    @Parameter(title: "Drink")
    var quantity: CaffeineAmountPreset

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            IntakeStore.shared.add(
                IntakeEntry(type: .caffeine, amount: quantity.mg, note: quantity.note),
                broadcast: true
            )
            WidgetCenter.shared.reloadAllTimelines()
        }
        return .result()
    }
}

struct LogAutoMealFullnessIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Fullness"

    @Parameter(title: "Level")
    var level: FullnessLevelPreset

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            let meal = MealAutoSelector.selectedMeal()
            IntakeStore.shared.add(
                IntakeEntry(type: .fullness, amount: Double(level.rawValue), note: level.note, meal: meal),
                broadcast: true
            )
            WidgetCenter.shared.reloadAllTimelines()
        }
        return .result()
    }
}

struct QuickAddOneGlassIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Add Water"

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            IntakeStore.shared.add(IntakeEntry(type: .water, amount: 1.0, note: "1 Glass"), broadcast: true)
            WidgetCenter.shared.reloadAllTimelines()
        }
        return .result()
    }
}

struct QuickAddCoffeeIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Add Coffee"

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            IntakeStore.shared.add(IntakeEntry(type: .caffeine, amount: 95, note: "Coffee"), broadcast: true)
            WidgetCenter.shared.reloadAllTimelines()
        }
        return .result()
    }
}

struct QuickAddSatisfiedFullnessIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Add Fullness"

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            let meal = MealAutoSelector.selectedMeal()
            IntakeStore.shared.add(
                IntakeEntry(type: .fullness, amount: 3, note: FullnessLevel.satisfied.label, meal: meal),
                broadcast: true
            )
            WidgetCenter.shared.reloadAllTimelines()
        }
        return .result()
    }
}
