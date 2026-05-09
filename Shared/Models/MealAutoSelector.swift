import Foundation

enum MealWindowDefaults {
    static let breakfastStart = 5 * 60
    static let lunchStart = 11 * 60
    static let snackStart = 15 * 60
    static let dinnerStart = 18 * 60
    static let lateNightStart = 23 * 60
}

enum MealWindowKeys {
    static let breakfastStartMinutes = "mealWindow.breakfastStartMinutes"
    static let lunchStartMinutes = "mealWindow.lunchStartMinutes"
    static let snackStartMinutes = "mealWindow.snackStartMinutes"
    static let dinnerStartMinutes = "mealWindow.dinnerStartMinutes"
    static let lateNightStartMinutes = "mealWindow.lateNightStartMinutes"
}

enum MealAutoSelector {
    static func selectedMeal(date: Date = Date(), defaults: UserDefaults = .standard) -> MealType {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)
        let totalMinutes = (hour * 60) + minute

        let breakfastStart = intValue(defaults, for: MealWindowKeys.breakfastStartMinutes, defaultValue: MealWindowDefaults.breakfastStart)
        let lunchStart = intValue(defaults, for: MealWindowKeys.lunchStartMinutes, defaultValue: MealWindowDefaults.lunchStart)
        let snackStart = intValue(defaults, for: MealWindowKeys.snackStartMinutes, defaultValue: MealWindowDefaults.snackStart)
        let dinnerStart = intValue(defaults, for: MealWindowKeys.dinnerStartMinutes, defaultValue: MealWindowDefaults.dinnerStart)
        let lateNightStart = intValue(defaults, for: MealWindowKeys.lateNightStartMinutes, defaultValue: MealWindowDefaults.lateNightStart)

        switch totalMinutes {
        case breakfastStart..<lunchStart:
            return .breakfast
        case lunchStart..<snackStart:
            return .lunch
        case snackStart..<dinnerStart:
            return .snack
        case dinnerStart..<lateNightStart:
            return .dinner
        default:
            // Outside configured windows, fallback to nearest preceding slot semantics.
            if totalMinutes < breakfastStart {
                return .dinner
            }
            return .snack
        }
    }

    private static func intValue(_ defaults: UserDefaults, for key: String, defaultValue: Int) -> Int {
        let v = defaults.integer(forKey: key)
        return v == 0 ? defaultValue : v
    }
}
