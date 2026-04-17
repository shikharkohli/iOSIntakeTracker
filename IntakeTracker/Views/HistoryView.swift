import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: IntakeStore
    @State private var filter: IntakeType? = nil

    private var filtered: [IntakeEntry] {
        guard let filter else { return store.entries }
        return store.entries.filter { $0.type == filter }
    }

    private var grouped: [(Date, [IntakeEntry])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: filtered) { cal.startOfDay(for: $0.timestamp) }
        return dict.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { day, entries in
                    Section(header: Text(day.formatted(date: .complete, time: .omitted))) {
                        ForEach(entries) { entry in
                            EntryRow(entry: entry)
                        }
                        .onDelete { offsets in
                            for index in offsets { store.remove(entries[index]) }
                        }
                    }
                }
                if filtered.isEmpty {
                    ContentUnavailableView("No entries yet", systemImage: "tray", description: Text("Log intake from the Today tab or your Apple Watch."))
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All") { filter = nil }
                        Divider()
                        ForEach(IntakeType.allCases) { type in
                            Button {
                                filter = type
                            } label: {
                                Label(type.displayName, systemImage: type.systemImage)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}

private struct EntryRow: View {
    let entry: IntakeEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.type.systemImage)
                .foregroundStyle(tint)
                .frame(width: 28)
            VStack(alignment: .leading) {
                Text(summary).font(.body)
                if let note = entry.note, !note.isEmpty {
                    Text(note).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(Formatting.time.string(from: entry.timestamp))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var tint: Color {
        switch entry.type {
        case .water: return .blue
        case .caffeine: return .brown
        case .fullness: return .orange
        case .weight: return .green
        case .waist: return .purple
        }
    }

    private var summary: String {
        switch entry.type {
        case .water: return Formatting.glasses(entry.amount)
        case .caffeine: return Formatting.mg(entry.amount)
        case .fullness:
            let level = FullnessLevel(rawValue: Int(entry.amount))
            return "\(level?.emoji ?? "") \(level?.label ?? "Fullness")"
        case .weight: return Formatting.weight(kg: entry.amount)
        case .waist: return Formatting.waist(cm: entry.amount)
        }
    }
}
