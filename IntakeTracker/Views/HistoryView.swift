import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: IntakeStore
    @State private var filter: IntakeType? = nil
    @State private var editingEntry: IntakeEntry?

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
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    if Calendar.current.isDateInToday(entry.timestamp) {
                                        Button("Edit") { editingEntry = entry }
                                            .tint(.blue)
                                    }
                                }
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
            .sheet(item: $editingEntry) { entry in
                EntryEditSheet(entry: entry) { updated in
                    store.updateEntry(updated)
                } onDelete: { deleting in
                    store.remove(deleting)
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

private struct EntryEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let entry: IntakeEntry
    let onSave: (IntakeEntry) -> Void
    let onDelete: (IntakeEntry) -> Void

    @State private var amount: Double
    @State private var note: String
    @State private var meal: MealType
    @State private var fullness: FullnessLevel
    @State private var showDeleteConfirmation = false

    init(entry: IntakeEntry, onSave: @escaping (IntakeEntry) -> Void, onDelete: @escaping (IntakeEntry) -> Void) {
        self.entry = entry
        self.onSave = onSave
        self.onDelete = onDelete
        let initialAmount: Double
        switch entry.type {
        case .weight:
            initialAmount = Formatting.display(fromKg: entry.amount)
        case .waist:
            initialAmount = Formatting.display(fromCm: entry.amount)
        default:
            initialAmount = entry.amount
        }
        _amount = State(initialValue: initialAmount)
        _note = State(initialValue: entry.note ?? "")
        _meal = State(initialValue: entry.meal ?? .snack)
        _fullness = State(initialValue: FullnessLevel(rawValue: Int(entry.amount)) ?? .satisfied)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Label(entry.type.displayName, systemImage: entry.type.systemImage)
                }
                switch entry.type {
                case .water:
                    Section("Amount") {
                        Stepper(value: $amount, in: 0...30, step: 0.5) {
                            Text(Formatting.glasses(amount))
                        }
                    }
                    Section("Note") { TextField("Optional", text: $note) }
                case .caffeine:
                    Section("Amount") {
                        Stepper(value: $amount, in: 0...1000, step: 5) {
                            Text(Formatting.mg(amount))
                        }
                    }
                    Section("Note") { TextField("e.g. Tea, Coffee", text: $note) }
                case .fullness:
                    Section("Meal") {
                        Picker("Meal", selection: $meal) {
                            ForEach(MealType.allCases) { m in
                                Text(m.displayName).tag(m)
                            }
                        }
                    }
                    Section("Fullness") {
                        Picker("Level", selection: $fullness) {
                            ForEach(FullnessLevel.allCases) { level in
                                Text("\(level.emoji) \(level.label)").tag(level)
                            }
                        }
                    }
                    Section("Note") {
                        TextField("Optional", text: $note)
                    }
                case .weight:
                    Section("Weight") {
                        Stepper(value: $amount, in: 20...300, step: Formatting.usesMetric ? 0.5 : 1) {
                            Text(Formatting.weight(kg: Formatting.kg(fromDisplay: amount)))
                        }
                    }
                case .waist:
                    Section("Waist") {
                        Stepper(value: $amount, in: 40...200, step: Formatting.usesMetric ? 0.5 : 0.5) {
                            Text(Formatting.waist(cm: Formatting.cm(fromDisplay: amount)))
                        }
                    }
                }
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Entry", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Edit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        let updated = buildUpdatedEntry(trimmedNote: trimmed)
                        onSave(updated)
                        dismiss()
                    }
                }
            }
            .alert("Delete this entry?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    onDelete(entry)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the log from your history.")
            }
        }
    }

    private func buildUpdatedEntry(trimmedNote: String) -> IntakeEntry {
        switch entry.type {
        case .fullness:
            return IntakeEntry(
                id: entry.id,
                type: entry.type,
                amount: Double(fullness.rawValue),
                timestamp: entry.timestamp,
                note: trimmedNote.isEmpty ? fullness.label : trimmedNote,
                meal: meal
            )
        case .weight:
            return IntakeEntry(
                id: entry.id,
                type: entry.type,
                amount: Formatting.kg(fromDisplay: amount),
                timestamp: entry.timestamp,
                note: nil,
                meal: nil
            )
        case .waist:
            return IntakeEntry(
                id: entry.id,
                type: entry.type,
                amount: Formatting.cm(fromDisplay: amount),
                timestamp: entry.timestamp,
                note: nil,
                meal: nil
            )
        default:
            return IntakeEntry(
                id: entry.id,
                type: entry.type,
                amount: amount,
                timestamp: entry.timestamp,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                meal: entry.meal
            )
        }
    }
}
