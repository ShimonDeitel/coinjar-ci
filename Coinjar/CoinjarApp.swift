import SwiftUI

@main
struct CoinjarApp: App {
    @StateObject private var store = CoinjarStore()
    @StateObject private var purchases = PurchaseManager()

    init() {
        // UI tests relaunch the app between cases without resetting the
        // simulator, so persisted kids/entries from an earlier test can
        // leak into a later one (e.g. testAddFirstKid expects the empty
        // state). Clear persisted data when launched with this flag.
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            store.deleteAllData()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
                .preferredColorScheme(.light)
        }
    }
}
