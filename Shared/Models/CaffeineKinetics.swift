import Foundation

enum CaffeineKinetics {
    static let halfLifeKey = "caffeine.halfLifeHours"
    static let defaultHalfLifeHours: Double = 5.0

    static func halfLifeHours(defaults: UserDefaults = .standard) -> Double {
        let v = defaults.double(forKey: halfLifeKey)
        return v > 0 ? v : defaultHalfLifeHours
    }

    static func currentBodyLoad(
        entries: [IntakeEntry],
        now: Date = Date(),
        halfLifeHours: Double
    ) -> Double {
        let caffeineEntries = entries.filter { $0.type == .caffeine && $0.timestamp <= now }
        guard !caffeineEntries.isEmpty else { return 0 }
        let safeHalfLife = max(0.5, halfLifeHours)
        return caffeineEntries.reduce(0) { partial, entry in
            partial + remainingDose(
                originalDoseMg: entry.amount,
                since: entry.timestamp,
                now: now,
                halfLifeHours: safeHalfLife
            )
        }
    }

    static func remainingDose(
        originalDoseMg: Double,
        since timestamp: Date,
        now: Date = Date(),
        halfLifeHours: Double
    ) -> Double {
        guard originalDoseMg > 0 else { return 0 }
        let elapsedHours = max(0, now.timeIntervalSince(timestamp) / 3600.0)
        let decay = pow(0.5, elapsedHours / max(0.5, halfLifeHours))
        return originalDoseMg * decay
    }
}
