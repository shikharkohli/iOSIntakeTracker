import Foundation
import Combine

@MainActor
final class IntakeStore: ObservableObject {
    static let shared = IntakeStore()

    @Published private(set) var entries: [IntakeEntry] = []

    private let storageKey = "intake.entries.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func add(_ entry: IntakeEntry, broadcast: Bool = true) {
        entries.append(entry)
        entries.sort { $0.timestamp > $1.timestamp }
        save()
        if broadcast {
            SyncService.shared.sendEntry(entry)
        }
    }

    func remove(_ entry: IntakeEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
        SyncService.shared.sendDelete(id: entry.id)
    }

    func mergeRemote(_ entry: IntakeEntry) {
        if entries.contains(where: { $0.id == entry.id }) { return }
        entries.append(entry)
        entries.sort { $0.timestamp > $1.timestamp }
        save()
    }

    func mergeRemoteDelete(id: UUID) {
        let before = entries.count
        entries.removeAll { $0.id == id }
        if entries.count != before { save() }
    }

    func replaceAll(_ newEntries: [IntakeEntry]) {
        entries = newEntries.sorted { $0.timestamp > $1.timestamp }
        save()
    }

    // MARK: - Queries

    func entries(on date: Date = Date(), type: IntakeType? = nil) -> [IntakeEntry] {
        let cal = Calendar.current
        return entries.filter { entry in
            (type == nil || entry.type == type!) &&
            cal.isDate(entry.timestamp, inSameDayAs: date)
        }
    }

    func total(of type: IntakeType, on date: Date = Date()) -> Double {
        entries(on: date, type: type).reduce(0) { $0 + $1.amount }
    }

    func latestFullness(on date: Date = Date()) -> IntakeEntry? {
        entries(on: date, type: .fullness).first
    }

    func latestEntry(type: IntakeType) -> IntakeEntry? {
        entries.first { $0.type == type }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([IntakeEntry].self, from: data) {
            entries = decoded.sorted { $0.timestamp > $1.timestamp }
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
