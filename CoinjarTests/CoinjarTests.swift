import XCTest
@testable import Coinjar

@MainActor
final class CoinjarTests: XCTestCase {
    private func makeStore() -> CoinjarStore {
        let suffix = UUID().uuidString
        return CoinjarStore(kidsFileName: "test_kids_\(suffix).json", entriesFileName: "test_entries_\(suffix).json")
    }

    func testAddKid() {
        let store = makeStore()
        let added = store.addKid(name: "Sam", savingsGoalCents: 2000, isPro: false)
        XCTAssertTrue(added)
        XCTAssertEqual(store.kids.count, 1)
        XCTAssertEqual(store.kids.first?.name, "Sam")
    }

    func testFreeLimitBlocksSecondKid() {
        let store = makeStore()
        _ = store.addKid(name: "Sam", savingsGoalCents: 2000, isPro: false)
        XCTAssertFalse(store.canAddKid(isPro: false))
        let added = store.addKid(name: "Jo", savingsGoalCents: 2000, isPro: false)
        XCTAssertFalse(added)
        XCTAssertEqual(store.kids.count, 1)
    }

    func testProAllowsMultipleKids() {
        let store = makeStore()
        _ = store.addKid(name: "Sam", savingsGoalCents: 2000, isPro: true)
        let added = store.addKid(name: "Jo", savingsGoalCents: 2000, isPro: true)
        XCTAssertTrue(added)
        XCTAssertEqual(store.kids.count, 2)
    }

    func testUpdateKid() {
        let store = makeStore()
        _ = store.addKid(name: "Sam", savingsGoalCents: 2000, isPro: false)
        guard let id = store.kids.first?.id else { return XCTFail("no kid") }
        store.updateKid(id, name: "Sammy", savingsGoalCents: 3000)
        XCTAssertEqual(store.kids.first?.name, "Sammy")
        XCTAssertEqual(store.kids.first?.savingsGoalCents, 3000)
    }

    func testDeleteKidRemovesEntries() {
        let store = makeStore()
        _ = store.addKid(name: "Sam", savingsGoalCents: 2000, isPro: false)
        guard let kidID = store.kids.first?.id else { return XCTFail("no kid") }
        store.addEntry(kidID: kidID, kind: .chore, label: "Dishes", amountCents: 100, date: Date())
        store.deleteKid(kidID)
        XCTAssertTrue(store.kids.isEmpty)
        XCTAssertTrue(store.entries(for: kidID).isEmpty)
    }

    func testAddEntryIncreasesBalance() {
        let store = makeStore()
        _ = store.addKid(name: "Sam", savingsGoalCents: 2000, isPro: false)
        guard let kidID = store.kids.first?.id else { return XCTFail("no kid") }
        store.addEntry(kidID: kidID, kind: .chore, label: "Dishes", amountCents: 100, date: Date())
        XCTAssertEqual(store.balanceCents(for: kidID), 100)
    }

    func testWithdrawalDecreasesBalance() {
        let store = makeStore()
        _ = store.addKid(name: "Sam", savingsGoalCents: 2000, isPro: false)
        guard let kidID = store.kids.first?.id else { return XCTFail("no kid") }
        store.addEntry(kidID: kidID, kind: .allowance, label: "Weekly", amountCents: 500, date: Date())
        store.addEntry(kidID: kidID, kind: .withdrawal, label: "Toy", amountCents: 200, date: Date())
        XCTAssertEqual(store.balanceCents(for: kidID), 300)
    }

    func testZeroOrNegativeAmountRejected() {
        let store = makeStore()
        _ = store.addKid(name: "Sam", savingsGoalCents: 2000, isPro: false)
        guard let kidID = store.kids.first?.id else { return XCTFail("no kid") }
        store.addEntry(kidID: kidID, kind: .chore, label: "Nothing", amountCents: 0, date: Date())
        XCTAssertEqual(store.entries(for: kidID).count, 0)
    }

    func testUpdateEntry() {
        let store = makeStore()
        _ = store.addKid(name: "Sam", savingsGoalCents: 2000, isPro: false)
        guard let kidID = store.kids.first?.id else { return XCTFail("no kid") }
        store.addEntry(kidID: kidID, kind: .chore, label: "Dishes", amountCents: 100, date: Date())
        guard let eid = store.entries(for: kidID).first?.id else { return XCTFail("no entry") }
        store.updateEntry(eid, kind: .bonus, label: "Bonus", amountCents: 200, date: Date())
        XCTAssertEqual(store.entries(for: kidID).first?.amountCents, 200)
        XCTAssertEqual(store.entries(for: kidID).first?.kind, .bonus)
    }

    func testDeleteEntry() {
        let store = makeStore()
        _ = store.addKid(name: "Sam", savingsGoalCents: 2000, isPro: false)
        guard let kidID = store.kids.first?.id else { return XCTFail("no kid") }
        store.addEntry(kidID: kidID, kind: .chore, label: "Dishes", amountCents: 100, date: Date())
        guard let eid = store.entries(for: kidID).first?.id else { return XCTFail("no entry") }
        store.deleteEntry(eid)
        XCTAssertTrue(store.entries(for: kidID).isEmpty)
    }

    func testJarFillRatioClampedToOne() {
        let store = makeStore()
        _ = store.addKid(name: "Sam", savingsGoalCents: 1000, isPro: false)
        guard let kidID = store.kids.first?.id else { return XCTFail("no kid") }
        store.addEntry(kidID: kidID, kind: .allowance, label: "Big", amountCents: 5000, date: Date())
        XCTAssertEqual(store.jarFillRatio(for: kidID), 1.0, accuracy: 0.001)
    }

    func testJarFillRatioProportional() {
        let store = makeStore()
        _ = store.addKid(name: "Sam", savingsGoalCents: 1000, isPro: false)
        guard let kidID = store.kids.first?.id else { return XCTFail("no kid") }
        store.addEntry(kidID: kidID, kind: .allowance, label: "Half", amountCents: 500, date: Date())
        XCTAssertEqual(store.jarFillRatio(for: kidID), 0.5, accuracy: 0.001)
    }

    func testDeleteAllData() {
        let store = makeStore()
        _ = store.addKid(name: "Sam", savingsGoalCents: 2000, isPro: false)
        guard let kidID = store.kids.first?.id else { return XCTFail("no kid") }
        store.addEntry(kidID: kidID, kind: .chore, label: "Dishes", amountCents: 100, date: Date())
        store.deleteAllData()
        XCTAssertTrue(store.kids.isEmpty)
    }

    func testSignedCentsForCreditAndDebit() {
        let credit = LedgerEntry(kidID: UUID(), kind: .chore, label: "", amountCents: 100)
        let debit = LedgerEntry(kidID: UUID(), kind: .withdrawal, label: "", amountCents: 100)
        XCTAssertEqual(credit.signedCents, 100)
        XCTAssertEqual(debit.signedCents, -100)
    }

    func testPersistenceRoundTrip() {
        let suffix = UUID().uuidString
        let kidsFile = "test_persist_kids_\(suffix).json"
        let entriesFile = "test_persist_entries_\(suffix).json"
        let store1 = CoinjarStore(kidsFileName: kidsFile, entriesFileName: entriesFile)
        _ = store1.addKid(name: "Persisted", savingsGoalCents: 2000, isPro: false)
        guard let kidID = store1.kids.first?.id else { return XCTFail("no kid") }
        store1.addEntry(kidID: kidID, kind: .chore, label: "Dishes", amountCents: 100, date: Date())

        let store2 = CoinjarStore(kidsFileName: kidsFile, entriesFileName: entriesFile)
        XCTAssertEqual(store2.kids.count, 1)
        XCTAssertEqual(store2.balanceCents(for: kidID), 100)
    }
}
