import Foundation

enum IntakeType: String, Codable, CaseIterable, Identifiable {
    case water
    case caffeine
    case fullness

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .water: return "Water"
        case .caffeine: return "Caffeine"
        case .fullness: return "Fullness"
        }
    }

    var systemImage: String {
        switch self {
        case .water: return "drop.fill"
        case .caffeine: return "cup.and.saucer.fill"
        case .fullness: return "fork.knife"
        }
    }
}

struct IntakeEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let type: IntakeType
    let amount: Double
    let timestamp: Date
    let note: String?

    init(id: UUID = UUID(), type: IntakeType, amount: Double, timestamp: Date = Date(), note: String? = nil) {
        self.id = id
        self.type = type
        self.amount = amount
        self.timestamp = timestamp
        self.note = note
    }
}

enum FullnessLevel: Int, CaseIterable, Identifiable {
    case stillHungry = 1
    case slightlyHungry = 2
    case satisfied = 3
    case full = 4
    case stuffed = 5

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .stillHungry: return "Still hungry"
        case .slightlyHungry: return "Slightly hungry"
        case .satisfied: return "Satisfied"
        case .full: return "Full"
        case .stuffed: return "Stuffed"
        }
    }

    var emoji: String {
        switch self {
        case .stillHungry: return "😋"
        case .slightlyHungry: return "🙂"
        case .satisfied: return "😊"
        case .full: return "😌"
        case .stuffed: return "🥴"
        }
    }
}

struct CaffeinePreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let milligrams: Double
    let systemImage: String

    static let presets: [CaffeinePreset] = [
        CaffeinePreset(name: "Coffee", milligrams: 95, systemImage: "cup.and.saucer.fill"),
        CaffeinePreset(name: "Espresso", milligrams: 63, systemImage: "cup.and.saucer"),
        CaffeinePreset(name: "Tea", milligrams: 40, systemImage: "leaf.fill"),
        CaffeinePreset(name: "Energy Drink", milligrams: 160, systemImage: "bolt.fill"),
        CaffeinePreset(name: "Soda", milligrams: 35, systemImage: "bubbles.and.sparkles")
    ]
}

struct WaterPreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let glasses: Double
    let systemImage: String

    static let presets: [WaterPreset] = [
        WaterPreset(name: "½ Glass", glasses: 0.5, systemImage: "drop"),
        WaterPreset(name: "1 Glass", glasses: 1.0, systemImage: "drop.fill"),
        WaterPreset(name: "Bottle", glasses: 2.0, systemImage: "waterbottle.fill")
    ]
}
