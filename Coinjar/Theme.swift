import SwiftUI

/// Coinjar's identity: playful bubblegum-pink/mint-green kid palette with a
/// warm coin-gold accent for the literal fillable-jar visual — distinct
/// from every sibling palette.
enum CJTheme {
    static let backdrop = Color(red: 0.988, green: 0.933, blue: 0.949)  // pale bubblegum pink
    static let surface = Color.white
    static let surfaceRaised = Color(red: 0.949, green: 0.882, blue: 0.910)
    static let ink = Color(red: 0.196, green: 0.153, blue: 0.184)       // deep berry-ink
    static let inkFaded = Color(red: 0.196, green: 0.153, blue: 0.184).opacity(0.56)
    static let rule = Color.black.opacity(0.08)

    static let bubblegum = Color(red: 0.945, green: 0.482, blue: 0.639)
    static let bubblegumDeep = Color(red: 0.816, green: 0.290, blue: 0.478)
    static let mint = Color(red: 0.376, green: 0.804, blue: 0.647)
    static let coinGold = Color(red: 0.933, green: 0.749, blue: 0.267)
    static let danger = Color(red: 0.729, green: 0.290, blue: 0.243)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
