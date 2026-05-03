import Foundation
import WatchConnectivity

/// Lightweight wrapper around WatchConnectivity that keeps the iPhone
/// and Apple Watch entry lists in sync. Deltas are sent via
/// `transferUserInfo` for reliability; full snapshots are sent through
/// `updateApplicationContext` so a freshly launched peer can catch up.
final class SyncService: NSObject {
    static let shared = SyncService()

    private let session: WCSession? = WCSession.isSupported() ? .default : nil

    private override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Outgoing

    func sendEntry(_ entry: IntakeEntry) {
        guard let session = session, session.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(entry) else { return }
        session.transferUserInfo(["entry": data])
    }

    func sendDelete(id: UUID) {
        guard let session = session, session.activationState == .activated else { return }
        session.transferUserInfo(["deletedId": id.uuidString])
    }

    func sendSnapshot(_ entries: [IntakeEntry]) {
        guard let session = session, session.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? session.updateApplicationContext(["snapshot": data])
    }

    /// Sends daily targets from iOS to the watch. Only called from iOS.
    func sendTargets(
        water: Double,
        caffeine: Double,
        weightKg: Double,
        waistCm: Double,
        breakfastStartMinutes: Int,
        lunchStartMinutes: Int,
        snackStartMinutes: Int,
        dinnerStartMinutes: Int,
        lateNightStartMinutes: Int
    ) {
        guard let session = session, session.activationState == .activated else { return }
        let targets: [String: Double] = [
            "waterGlasses": water,
            "caffeineMg": caffeine,
            "weightKg": weightKg,
            "waistCm": waistCm,
            "breakfastStartMinutes": Double(breakfastStartMinutes),
            "lunchStartMinutes": Double(lunchStartMinutes),
            "snackStartMinutes": Double(snackStartMinutes),
            "dinnerStartMinutes": Double(dinnerStartMinutes),
            "lateNightStartMinutes": Double(lateNightStartMinutes)
        ]
        guard let data = try? JSONEncoder().encode(targets) else { return }
        session.transferUserInfo(["targets": data])
    }
}

extension SyncService: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        if let data = userInfo["entry"] as? Data,
           let entry = try? JSONDecoder().decode(IntakeEntry.self, from: data) {
            Task { @MainActor in IntakeStore.shared.mergeRemote(entry) }
        }
        if let idString = userInfo["deletedId"] as? String,
           let id = UUID(uuidString: idString) {
            Task { @MainActor in IntakeStore.shared.mergeRemoteDelete(id: id) }
        }
        if let data = userInfo["targets"] as? Data,
           let targets = try? JSONDecoder().decode([String: Double].self, from: data) {
            Task { @MainActor in
                if let v = targets["waterGlasses"] { UserDefaults.standard.set(v, forKey: "target.waterGlasses") }
                if let v = targets["caffeineMg"] { UserDefaults.standard.set(v, forKey: "target.caffeineMg") }
                if let v = targets["weightKg"] { UserDefaults.standard.set(v, forKey: "target.weightKg") }
                if let v = targets["waistCm"] { UserDefaults.standard.set(v, forKey: "target.waistCm") }
                if let v = targets["breakfastStartMinutes"] {
                    UserDefaults.standard.set(Int(v), forKey: MealWindowKeys.breakfastStartMinutes)
                }
                if let v = targets["lunchStartMinutes"] {
                    UserDefaults.standard.set(Int(v), forKey: MealWindowKeys.lunchStartMinutes)
                }
                if let v = targets["snackStartMinutes"] {
                    UserDefaults.standard.set(Int(v), forKey: MealWindowKeys.snackStartMinutes)
                }
                if let v = targets["dinnerStartMinutes"] {
                    UserDefaults.standard.set(Int(v), forKey: MealWindowKeys.dinnerStartMinutes)
                }
                if let v = targets["lateNightStartMinutes"] {
                    UserDefaults.standard.set(Int(v), forKey: MealWindowKeys.lateNightStartMinutes)
                }
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let data = applicationContext["snapshot"] as? Data,
           let entries = try? JSONDecoder().decode([IntakeEntry].self, from: data) {
            Task { @MainActor in IntakeStore.shared.replaceAll(entries) }
        }
    }
}
