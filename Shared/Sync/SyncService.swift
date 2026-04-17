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
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let data = applicationContext["snapshot"] as? Data,
           let entries = try? JSONDecoder().decode([IntakeEntry].self, from: data) {
            Task { @MainActor in IntakeStore.shared.replaceAll(entries) }
        }
    }
}
