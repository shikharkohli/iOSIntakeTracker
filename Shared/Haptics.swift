import Foundation
#if canImport(WatchKit)
import WatchKit
#endif

enum Haptic {
    static func tapLog() {
        #if canImport(WatchKit)
        WKInterfaceDevice.current().play(.click)
        #endif
    }

    static func crownStep() {
        #if canImport(WatchKit)
        WKInterfaceDevice.current().play(.click)
        #endif
    }

    /// Fires `.success` once per metric per local day.
    static func goalReached(_ metric: MetricKind, defaults: UserDefaults = .standard, now: Date = Date()) {
        guard shouldFireGoal(metric, defaults: defaults, now: now) else { return }
        #if canImport(WatchKit)
        WKInterfaceDevice.current().play(.success)
        #endif
    }

    /// Pure debounce check — testable. Returns true when the haptic should fire,
    /// and records the day so the next same-day call returns false.
    @discardableResult
    static func shouldFireGoal(_ metric: MetricKind, defaults: UserDefaults, now: Date) -> Bool {
        let key = "haptic.goal.\(metric.rawValue).day"
        let today = Calendar.current.startOfDay(for: now).timeIntervalSince1970
        let last = defaults.double(forKey: key)
        if last == today { return false }
        defaults.set(today, forKey: key)
        return true
    }
}
