import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            CoinjarHomeView()
                .tabItem {
                    Label("Jar", systemImage: "dollarsign.circle.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(CJTheme.bubblegumDeep)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(CJTheme.surface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(CoinjarStore())
        .environmentObject(PurchaseManager())
}
