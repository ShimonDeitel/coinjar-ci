import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: CoinjarStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("coinjar_confirm_withdrawals") private var confirmWithdrawals: Bool = true
    @State private var activeSheet: CoinjarSheet?
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Ledger") {
                    Toggle("Confirm before withdrawals", isOn: $confirmWithdrawals)
                        .accessibilityIdentifier("confirmWithdrawalsToggle")
                }

                Section("Kids") {
                    ForEach(store.kids) { kid in
                        Button(kid.name) {
                            activeSheet = .editKid(kid)
                        }
                        .buttonStyle(.plain)
                    }
                    Button("Add Kid") {
                        if store.canAddKid(isPro: purchases.isPro) {
                            activeSheet = .addKid
                        } else {
                            activeSheet = .paywall
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settingsAddKidButton")
                }

                Section("Coinjar Pro") {
                    if purchases.isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(CJTheme.mint)
                    } else {
                        Button("Upgrade to Pro") {
                            activeSheet = .paywall
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("upgradeProButton")
                    }
                    Button("Restore Purchases") {
                        Task {
                            await purchases.restore()
                            restoreMessage = purchases.isPro ? "Purchases restored." : "No purchases found."
                        }
                    }
                    .buttonStyle(.plain)
                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.caption)
                            .foregroundStyle(CJTheme.inkFaded)
                    }
                }

                Section("About") {
                    Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/coinjar-site/privacy.html")!)
                    Link("Contact Support", destination: URL(string: "mailto:s0533495227@gmail.com")!)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(CJTheme.inkFaded)
                    }
                }

                Section {
                    Button("Reset All Data", role: .destructive) {
                        showResetConfirm = true
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset all kids and ledger entries?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    store.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addKid:
                    KidFormView(existing: nil)
                case .editKid(let kid):
                    KidFormView(existing: kid)
                case .paywall:
                    PaywallView()
                default:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(CoinjarStore())
        .environmentObject(PurchaseManager())
}
