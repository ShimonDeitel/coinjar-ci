import SwiftUI

/// One unified sheet enum for the whole app — a single `.sheet(item:)` per
/// screen, per the standing rule.
enum CoinjarSheet: Identifiable {
    case addKid
    case editKid(Kid)
    case addEntry(kidID: UUID)
    case editEntry(LedgerEntry)
    case paywall

    var id: String {
        switch self {
        case .addKid: return "addKid"
        case .editKid(let k): return "editKid-\(k.id)"
        case .addEntry(let id): return "addEntry-\(id)"
        case .editEntry(let e): return "editEntry-\(e.id)"
        case .paywall: return "paywall"
        }
    }
}

struct KidFormView: View {
    @EnvironmentObject private var store: CoinjarStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    let existing: Kid?

    @State private var name: String
    @State private var goalDollars: String

    init(existing: Kid?) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        let goalCents = existing?.savingsGoalCents ?? 2000
        _goalDollars = State(initialValue: String(format: "%.2f", Double(goalCents) / 100.0))
    }

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Kid") {
                    TextField("Name", text: $name)
                        .accessibilityIdentifier("kidNameField")
                }

                Section("Jar Goal") {
                    HStack {
                        Text("$")
                        TextField("20.00", text: $goalDollars)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("goalField")
                    }
                    Text("The jar visual fills up as savings approach this goal.")
                        .font(.caption)
                        .foregroundStyle(CJTheme.inkFaded)
                }

                if isEditing {
                    Section {
                        Button("Delete Kid", role: .destructive) {
                            if let existing {
                                store.deleteKid(existing.id)
                            }
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("deleteKidButton")
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Edit Kid" : "New Kid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .buttonStyle(.plain)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("saveKidButton")
                }
            }
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let goalCents = Int((Double(goalDollars) ?? 20.0) * 100)
        if let existing {
            store.updateKid(existing.id, name: name, savingsGoalCents: goalCents)
            dismiss()
        } else {
            guard store.canAddKid(isPro: purchases.isPro) else { return }
            store.addKid(name: name, savingsGoalCents: goalCents, isPro: purchases.isPro)
            dismiss()
        }
    }
}

struct EntryFormView: View {
    @EnvironmentObject private var store: CoinjarStore
    @Environment(\.dismiss) private var dismiss

    let kidID: UUID
    let existing: LedgerEntry?

    @State private var kind: LedgerEntryKind
    @State private var label: String
    @State private var amountDollars: String
    @State private var date: Date

    init(kidID: UUID, existing: LedgerEntry?) {
        self.kidID = kidID
        self.existing = existing
        _kind = State(initialValue: existing?.kind ?? .chore)
        _label = State(initialValue: existing?.label ?? "")
        let cents = existing?.amountCents ?? 100
        _amountDollars = State(initialValue: String(format: "%.2f", Double(cents) / 100.0))
        _date = State(initialValue: existing?.date ?? Date())
    }

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Kind", selection: $kind) {
                        ForEach(LedgerEntryKind.allCases) { k in
                            Text(k.rawValue).tag(k)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("kindPicker")
                }

                Section("Details") {
                    TextField("What was it for? (e.g. Dishes)", text: $label)
                        .accessibilityIdentifier("labelField")
                    HStack {
                        Text("$")
                        TextField("1.00", text: $amountDollars)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("amountField")
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .accessibilityIdentifier("entryDateField")
                }

                if isEditing {
                    Section {
                        Button("Delete Entry", role: .destructive) {
                            if let existing {
                                store.deleteEntry(existing.id)
                            }
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("deleteEntryButton")
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .buttonStyle(.plain)
                        .disabled((Double(amountDollars) ?? 0) <= 0)
                        .accessibilityIdentifier("saveEntryButton")
                }
            }
        }
    }

    private func save() {
        let cents = Int((Double(amountDollars) ?? 0) * 100)
        guard cents > 0 else { return }
        if let existing {
            store.updateEntry(existing.id, kind: kind, label: label, amountCents: cents, date: date)
            dismiss()
        } else {
            store.addEntry(kidID: kidID, kind: kind, label: label, amountCents: cents, date: date)
            dismiss()
        }
    }
}
