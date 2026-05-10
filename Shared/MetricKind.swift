import SwiftUI

enum MetricKind: String, CaseIterable, Identifiable {
    case water, caffeine, fullness, weight, waist

    var id: String { rawValue }

    var intakeType: IntakeType {
        switch self {
        case .water:    return .water
        case .caffeine: return .caffeine
        case .fullness: return .fullness
        case .weight:   return .weight
        case .waist:    return .waist
        }
    }

    var displayName: String { intakeType.displayName }
    var glyph: String { intakeType.systemImage }

    var color: Color {
        switch self {
        case .water:    return WatchTheme.Color.water
        case .caffeine: return WatchTheme.Color.caffeine
        case .fullness: return WatchTheme.Color.fullness
        case .weight:   return WatchTheme.Color.weight
        case .waist:    return WatchTheme.Color.waist
        }
    }

    var targetKey: String {
        switch self {
        case .water:    return "target.waterGlasses"
        case .caffeine: return "target.caffeineMg"
        case .fullness: return "target.mealsPerDay"
        case .weight:   return "target.weightKg"
        case .waist:    return "target.waistCm"
        }
    }

    var defaultTarget: Double {
        switch self {
        case .water:    return 8
        case .caffeine: return 400
        case .fullness: return 4
        case .weight:   return 70
        case .waist:    return 80
        }
    }

    func format(_ value: Double) -> String {
        switch self {
        case .water:    return Formatting.glasses(value)
        case .caffeine: return Formatting.mg(value)
        case .fullness: return "\(Int(value))"
        case .weight:   return Formatting.weight(kg: value)
        case .waist:    return Formatting.waist(cm: value)
        }
    }
}
