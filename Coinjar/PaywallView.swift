import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var purchasing = false

    var body: some View {
        NavigationStack {
            ZStack {
                CJTheme.backdrop.ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(CJTheme.coinGold)
                        .padding(.top, 40)

                    Text("Coinjar Pro")
                        .font(CJTheme.titleFont)
                        .foregroundStyle(CJTheme.ink)

                    VStack(alignment: .leading, spacing: 14) {
                        featureRow("person.2.fill", "Track unlimited kids")
                        featureRow("chart.bar.fill", "Full chore & allowance history")
                        featureRow("sparkles", "Support future updates")
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    Button {
                        purchasing = true
                        Task {
                            await purchases.purchase()
                            purchasing = false
                            if purchases.isPro { dismiss() }
                        }
                    } label: {
                        HStack {
                            if purchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text(purchases.product.map { "Unlock for \($0.displayPrice)" } ?? "Unlock Pro")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(CJTheme.bubblegumDeep)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(purchasing || purchases.product == nil)
                    .padding(.horizontal, 24)

                    Button("Restore Purchases") {
                        Task { await purchases.restore() }
                    }
                    .buttonStyle(.plain)
                    .font(.footnote)
                    .foregroundStyle(CJTheme.inkFaded)
                    .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .buttonStyle(.plain)
                        .foregroundStyle(CJTheme.ink)
                }
            }
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(CJTheme.bubblegumDeep)
                .frame(width: 24)
            Text(text)
                .foregroundStyle(CJTheme.ink)
        }
    }
}

#Preview {
    PaywallView().environmentObject(PurchaseManager())
}
