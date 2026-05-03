import Foundation

enum WatchDeepLinkRouter {
    static func route(url: URL) -> WatchRootView.Page? {
        guard url.scheme == "intaketracker" else { return nil }
        guard url.host == "open" else { return nil }

        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        switch path {
        case "summary": return .summary
        case "water": return .water
        case "caffeine": return .caffeine
        case "fullness": return .fullness
        case "weight": return .weight
        case "waist": return .waist
        default: return nil
        }
    }
}

