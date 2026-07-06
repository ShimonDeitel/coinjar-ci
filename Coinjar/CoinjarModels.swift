import Foundation

struct Kid: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var savingsGoalCents: Int?
    var createdDate: Date

    init(id: UUID = UUID(), name: String, savingsGoalCents: Int? = nil, createdDate: Date = Date()) {
        self.id = id
        self.name = name
        self.savingsGoalCents = savingsGoalCents
        self.createdDate = createdDate
    }
}

enum LedgerEntryKind: String, Codable, CaseIterable, Identifiable {
    case chore = "Chore"
    case allowance = "Allowance"
    case bonus = "Bonus"
    case withdrawal = "Withdrawal"

    var id: String { rawValue }

    /// Positive entries add coins to the jar, withdrawals remove them.
    var isCredit: Bool { self != .withdrawal }
}

struct LedgerEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var kidID: UUID
    var kind: LedgerEntryKind
    var label: String
    var amountCents: Int   // always stored positive; sign derived from kind
    var date: Date
    var createdDate: Date

    init(
        id: UUID = UUID(),
        kidID: UUID,
        kind: LedgerEntryKind,
        label: String,
        amountCents: Int,
        date: Date = Date(),
        createdDate: Date = Date()
    ) {
        self.id = id
        self.kidID = kidID
        self.kind = kind
        self.label = label
        self.amountCents = amountCents
        self.date = date
        self.createdDate = createdDate
    }

    var signedCents: Int { kind.isCredit ? amountCents : -amountCents }
}
