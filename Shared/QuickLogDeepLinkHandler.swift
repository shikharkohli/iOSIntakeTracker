import Foundation

enum QuickLogDeepLinkHandler {
    /// Entry point that is safe to call from nonisolated contexts (Swift 6).
    /// Performs the actual store mutation on the main actor.
    static func handle(url: URL, store: IntakeStore) {
        Task { @MainActor in
            handleOnMain(url: url, store: store)
        }
    }

    @MainActor
    private static func handleOnMain(url: URL, store: IntakeStore) {
        guard url.scheme == "intaketracker" else { return }
        guard url.host == "quicklog" else { return }

        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = comps?.queryItems ?? []

        func q(_ name: String) -> String? { items.first(where: { $0.name == name })?.value }

        switch path {
        case "water":
            let glasses = Double(q("glasses") ?? "") ?? 1.0
            store.add(IntakeEntry(type: .water, amount: glasses, note: "Quick log"), broadcast: true)

        case "caffeine":
            let mg = Double(q("mg") ?? "") ?? 95
            let note = q("note")
            store.add(IntakeEntry(type: .caffeine, amount: mg, note: note), broadcast: true)

        case "fullness":
            let level = Double(q("level") ?? "") ?? 3
            let meal = MealAutoSelector.selectedMeal()
            let levelNote = FullnessLevel(rawValue: Int(level))?.label
            store.add(IntakeEntry(type: .fullness, amount: level, note: levelNote, meal: meal), broadcast: true)

        default:
            return
        }
    }
}
