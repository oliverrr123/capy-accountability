import SwiftUI

enum CapyButtonStyle {
    case primary
    case secondary

    var backgroundColor: Color {
        switch self {
        case .primary:
            return .capyBeige
        case .secondary:
            return .capyBrown
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary:
            return .capyBrown
        case .secondary:
            return .capyBeige
        }
    }
}

struct CapyButton: View {
    let title: String
    var style: CapyButtonStyle = .primary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Gaegu-Regular", size: 28))
                .foregroundStyle(style.foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
        }
        .background(style.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

#Preview {
    VStack(spacing: 16) {
        CapyButton(title: "Continue", action: {})
        CapyButton(title: "Agree", style: .secondary, action: {})
    }
    .padding()
    .background(Color.capyBlue)
}
