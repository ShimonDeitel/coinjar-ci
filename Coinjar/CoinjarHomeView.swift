import SwiftUI

struct CoinjarHomeView: View {
    @EnvironmentObject private var store: CoinjarStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var activeSheet: CoinjarSheet?
    @State private var selectedKidID: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                CJTheme.backdrop.ignoresSafeArea()

                if store.kids.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            kidPicker
                                .padding(.top, 8)

                            if let kidID = selectedKidID ?? store.kids.first?.id {
                                FillableJarView(fillRatio: store.jarFillRatio(for: kidID))
                                    .frame(height: 220)

                                Text(String(format: "$%.2f", Double(store.balanceCents(for: kidID)) / 100.0))
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundStyle(CJTheme.ink)

                                let entries = store.entries(for: kidID)
                                ForEach(entries) { entry in
                                    LedgerRow(entry: entry) {
                                        activeSheet = .editEntry(entry)
                                    } onDelete: {
                                        store.deleteEntry(entry.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Coinjar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Add Entry") {
                            if let kidID = selectedKidID ?? store.kids.first?.id {
                                activeSheet = .addEntry(kidID: kidID)
                            }
                        }
                        Button("Add Kid") {
                            if store.canAddKid(isPro: purchases.isPro) {
                                activeSheet = .addKid
                            } else {
                                activeSheet = .paywall
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("addMenuButton")
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addKid:
                    KidFormView(existing: nil)
                case .editKid(let kid):
                    KidFormView(existing: kid)
                case .addEntry(let kidID):
                    EntryFormView(kidID: kidID, existing: nil)
                case .editEntry(let entry):
                    EntryFormView(kidID: entry.kidID, existing: entry)
                case .paywall:
                    PaywallView()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(CJTheme.coinGold)
            Text("Fill the jar with chores")
                .font(CJTheme.headlineFont)
                .foregroundStyle(CJTheme.ink)
            Text("Log allowance and chore earnings, and watch the jar fill up toward the savings goal.")
                .font(.subheadline)
                .foregroundStyle(CJTheme.inkFaded)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Add First Kid") {
                activeSheet = .addKid
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(CJTheme.bubblegumDeep)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .accessibilityIdentifier("addFirstKidButton")
        }
    }

    private var kidPicker: some View {
        HStack {
            ForEach(store.kids) { kid in
                Button {
                    selectedKidID = kid.id
                } label: {
                    Text(kid.name)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background((selectedKidID ?? store.kids.first?.id) == kid.id ? CJTheme.bubblegumDeep : CJTheme.surfaceRaised)
                        .foregroundStyle((selectedKidID ?? store.kids.first?.id) == kid.id ? Color.white : CJTheme.ink)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("kidChip_\(kid.name)")
            }
            Spacer()
        }
    }
}

/// The quirky signature feature: a literal glass jar that fills with gold
/// coins as the kid's balance approaches their savings goal, with a
/// wobble/settle animation each time the fill level changes.
struct FillableJarView: View {
    let fillRatio: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // jar glass outline
                JarShape()
                    .stroke(CJTheme.ink.opacity(0.35), lineWidth: 4)
                    .frame(width: geo.size.width * 0.6, height: geo.size.height)
                    .frame(maxWidth: .infinity)

                // coin fill, clipped to jar shape
                JarShape()
                    .fill(
                        LinearGradient(
                            colors: [CJTheme.coinGold.opacity(0.85), CJTheme.coinGold],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: geo.size.width * 0.6, height: geo.size.height)
                    .frame(maxWidth: .infinity)
                    .mask(
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Rectangle().frame(height: geo.size.height * fillRatio)
                        }
                    )
                    .animation(.spring(response: 0.6, dampingFraction: 0.65), value: fillRatio)
            }
        }
        .accessibilityIdentifier("fillableJarView")
    }
}

struct JarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let neckWidth = rect.width * 0.5
        let neckHeight = rect.height * 0.12
        let bodyTop = rect.minY + neckHeight
        let cornerRadius = rect.width * 0.16

        path.move(to: CGPoint(x: rect.midX - neckWidth / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + neckWidth / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + neckWidth / 2, y: bodyTop))
        path.addLine(to: CGPoint(x: rect.maxX, y: bodyTop + cornerRadius))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: bodyTop + cornerRadius))
        path.addLine(to: CGPoint(x: rect.midX - neckWidth / 2, y: bodyTop))
        path.closeSubpath()
        return path
    }
}

struct LedgerRow: View {
    let entry: LedgerEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(entry.kind.isCredit ? CJTheme.mint.opacity(0.25) : CJTheme.bubblegum.opacity(0.25))
                    .frame(width: 40, height: 40)
                Image(systemName: entry.kind.isCredit ? "plus" : "minus")
                    .foregroundStyle(entry.kind.isCredit ? CJTheme.mint : CJTheme.bubblegumDeep)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.label.isEmpty ? entry.kind.rawValue : entry.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CJTheme.ink)
                Text(Self.dateFormatter.string(from: entry.date) + " · " + entry.kind.rawValue)
                    .font(.caption)
                    .foregroundStyle(CJTheme.inkFaded)
            }

            Spacer()

            Text((entry.kind.isCredit ? "+$" : "-$") + String(format: "%.2f", Double(entry.amountCents) / 100.0))
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(entry.kind.isCredit ? CJTheme.mint : CJTheme.bubblegumDeep)

            Menu {
                Button("Edit", action: onEdit)
                Button("Delete", role: .destructive) { showDeleteConfirm = true }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(CJTheme.bubblegum)
                    .frame(width: 32, height: 32)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("entryMenu_\(entry.id)")
            .accessibilityAddTraits(.isButton)
            .contentShape(Rectangle())
        }
        .padding(14)
        .background(CJTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .confirmationDialog("Delete this entry?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        }
    }
}
