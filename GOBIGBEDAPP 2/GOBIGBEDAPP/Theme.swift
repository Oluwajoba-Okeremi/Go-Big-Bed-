import SwiftUI


enum Theme {

    static let black: Color = .black


    static let red: Color = Color(red: 0.90, green: 0.22, blue: 0.24)


    static let text: Color = .white
    static let textMuted: Color = .white.opacity(0.70)


    static let card: Color = Color(.secondarySystemBackground)
}


struct CardModifier: ViewModifier {
    var cornerRadius: CGFloat = 18
    var padding: CGFloat = 16
    var background: Color = Theme.card
    var borderOpacity: Double = 0.10
    var shadowRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(borderOpacity), lineWidth: 0.5)
            )
            .shadow(radius: shadowRadius, y: 2)
    }
}

extension View {

    func card(
        cornerRadius: CGFloat = 18,
        padding: CGFloat = 16,
        background: Color = Theme.card
    ) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius, padding: padding, background: background))
    }
}


struct PrimaryButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 14
    var height: CGFloat = 48

    init() {}

    func makeBody(configuration: Configuration) -> some View {
        PrimaryButton(configuration: configuration,
                      cornerRadius: cornerRadius,
                      height: height)
    }

    private struct PrimaryButton: View {
        @Environment(\.isEnabled) private var isEnabled
        let configuration: ButtonStyle.Configuration
        let cornerRadius: CGFloat
        let height: CGFloat

        var body: some View {
            let base = Theme.red
            let pressed = base.opacity(0.85)
            let disabled = base.opacity(0.45)

            return configuration.label
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(isEnabled ? (configuration.isPressed ? pressed : base) : disabled)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 0.5)
                )
                .shadow(radius: configuration.isPressed ? 2 : 6, y: configuration.isPressed ? 1 : 3)
                .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
        }
    }
}
