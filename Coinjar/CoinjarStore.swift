import Foundation

@MainActor
final class CoinjarStore: ObservableObject {
    @Published private(set) var kids: [Kid] = []
    @Published private(set) var entries: [LedgerEntry] = []

    /// Free tier: 1 kid, unlimited entries for that kid. Pro unlocks
    /// additional kids (siblings sharing one device).
    private let freeKidLimit = 1
    private let kidsURL: URL
    private let entriesURL: URL

    init(kidsFileName: String = "coinjar_kids.json", entriesFileName: String = "coinjar_entries.json") {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        kidsURL = dir.appendingPathComponent(kidsFileName)
        entriesURL = dir.appendingPathComponent(entriesFileName)
        load()
    }

    func canAddKid(isPro: Bool) -> Bool {
        isPro || kids.count < freeKidLimit
    }

    @discardableResult
    func addKid(name: String, savingsGoalCents: Int?, isPro: Bool) -> Bool {
        guard canAddKid(isPro: isPro) else { return false }
        kids.append(Kid(name: name, savingsGoalCents: savingsGoalCents))
        saveKids()
        return true
    }

    func updateKid(_ id: UUID, name: String, savingsGoalCents: Int?) {
        guard let idx = kids.firstIndex(where: { $0.id == id }) else { return }
        kids[idx].name = name
        kids[idx].savingsGoalCents = savingsGoalCents
        saveKids()
    }

    func deleteKid(_ id: UUID) {
        kids.removeAll { $0.id == id }
        entries.removeAll { $0.kidID == id }
        saveKids()
        saveEntries()
    }

    func entries(for kidID: UUID) -> [LedgerEntry] {
        entries.filter { $0.kidID == kidID }.sorted { $0.date > $1.date }
    }

    func balanceCents(for kidID: UUID) -> Int {
        entries.filter { $0.kidID == kidID }.reduce(0) { $0 + $1.signedCents }
    }

    func addEntry(kidID: UUID, kind: LedgerEntryKind, label: String, amountCents: Int, date: Date) {
        guard amountCents > 0 else { return }
        entries.append(LedgerEntry(kidID: kidID, kind: kind, label: label, amountCents: amountCents, date: date))
        saveEntries()
    }

    func updateEntry(_ id: UUID, kind: LedgerEntryKind, label: String, amountCents: Int, date: Date) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].kind = kind
        entries[idx].label = label
        entries[idx].amountCents = amountCents
        entries[idx].date = date
        saveEntries()
    }

    func deleteEntry(_ id: UUID) {
        entries.removeAll { $0.id == id }
        saveEntries()
    }

    func deleteAllData() {
        kids.removeAll()
        entries.removeAll()
        saveKids()
        saveEntries()
    }

    /// The signature "fillable jar" feature: how full the literal jar
    /// visual should render, as a 0...1 ratio of balance against the kid's
    /// savings goal (or a sensible default cap if no goal is set).
    func jarFillRatio(for kidID: UUID) -> Double {
        let balance = balanceCents(for: kidID)
        let goal = kids.first(where: { $0.id == kidID })?.savingsGoalCents ?? 2000  // default $20 cap
        guard goal > 0 else { return 0 }
        return min(1.0, max(0.0, Double(balance) / Double(goal)))
    }

    private func load() {
        if let data = try? Data(contentsOf: kidsURL),
           let decoded = try? JSONDecoder().decode([Kid].self, from: data) {
            kids = decoded
        }
        if let data = try? Data(contentsOf: entriesURL),
           let decoded = try? JSONDecoder().decode([LedgerEntry].self, from: data) {
            entries = decoded
        }
    }

    private func saveKids() {
        guard let data = try? JSONEncoder().encode(kids) else { return }
        try? data.write(to: kidsURL, options: .atomic)
    }

    private func saveEntries() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: entriesURL, options: .atomic)
    }
}
