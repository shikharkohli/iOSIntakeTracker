import Foundation
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    enum Status {
        case unavailable
        case undetermined
        case authorized
        case denied
    }

    struct SleepSession: Identifiable, Hashable {
        var id: Date { wakeDate }
        /// Local day that the user fell asleep on (the "Tuesday night" of "Tuesday->Wednesday").
        let nightOf: Date
        let wakeDate: Date
        let hoursAsleep: Double
    }

    @Published private(set) var status: Status = .undetermined
    @Published private(set) var sessions: [SleepSession] = []

    private let store = HKHealthStore()
    private let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    init() {
        if !Self.isAvailable { status = .unavailable }
    }

    func requestAuthorization() async {
        guard Self.isAvailable, let sleepType else { status = .unavailable; return }
        do {
            try await store.requestAuthorization(toShare: [], read: [sleepType])
            // HealthKit deliberately doesn't reveal read-only authorization status;
            // we infer it by trying to read and seeing if we get anything back.
            await refresh()
            status = sessions.isEmpty ? .undetermined : .authorized
        } catch {
            status = .denied
        }
    }

    func refresh(days: Int = 90) async {
        guard Self.isAvailable, let sleepType else { return }
        let calendar = Calendar.current
        let end = Date()
        let start = calendar.date(byAdding: .day, value: -days, to: end) ?? end

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        do {
            let samples = try await descriptor.result(for: store)
            sessions = Self.aggregate(samples: samples, calendar: calendar)
            if !sessions.isEmpty { status = .authorized }
        } catch {
            sessions = []
        }
    }

    private static let asleepValues: Set<Int> = {
        var values: Set<Int> = [HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue]
        values.insert(HKCategoryValueSleepAnalysis.asleepCore.rawValue)
        values.insert(HKCategoryValueSleepAnalysis.asleepDeep.rawValue)
        values.insert(HKCategoryValueSleepAnalysis.asleepREM.rawValue)
        return values
    }()

    /// Groups consecutive asleep samples (within 4h of each other) into sessions.
    /// A session's "nightOf" is the local day it most likely began on:
    /// samples that start before 6am are attributed to the previous evening.
    private static func aggregate(samples: [HKCategorySample], calendar: Calendar) -> [SleepSession] {
        let asleep = samples.filter { asleepValues.contains($0.value) }
        guard !asleep.isEmpty else { return [] }

        var sessions: [SleepSession] = []
        var sessionStart = asleep[0].startDate
        var sessionEnd = asleep[0].endDate
        var duration: TimeInterval = asleep[0].endDate.timeIntervalSince(asleep[0].startDate)

        for sample in asleep.dropFirst() {
            if sample.startDate.timeIntervalSince(sessionEnd) > 4 * 3600 {
                sessions.append(makeSession(start: sessionStart, end: sessionEnd, duration: duration, calendar: calendar))
                sessionStart = sample.startDate
                sessionEnd = sample.endDate
                duration = sample.endDate.timeIntervalSince(sample.startDate)
            } else {
                sessionEnd = max(sessionEnd, sample.endDate)
                duration += sample.endDate.timeIntervalSince(sample.startDate)
            }
        }
        sessions.append(makeSession(start: sessionStart, end: sessionEnd, duration: duration, calendar: calendar))
        // Keep only sessions of at least 1 hour to filter out naps and noise
        return sessions.filter { $0.hoursAsleep >= 1 }
    }

    private static func makeSession(start: Date, end: Date, duration: TimeInterval, calendar: Calendar) -> SleepSession {
        // If the session started before 6am, attribute it to the previous evening.
        let hour = calendar.component(.hour, from: start)
        let attributionAnchor = hour < 6 ? calendar.date(byAdding: .day, value: -1, to: start) ?? start : start
        let nightOf = calendar.startOfDay(for: attributionAnchor)
        return SleepSession(nightOf: nightOf, wakeDate: end, hoursAsleep: duration / 3600)
    }
}
