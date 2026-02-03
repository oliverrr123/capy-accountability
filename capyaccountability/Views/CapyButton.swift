import SwiftUI

enum CapyButtonStyle {
    case primary
    case secondary
    case skyLight(base: Color, overlay: String)

    var backgroundColor: Color {
        switch self {
            case .primary: return .capyBeige
            case .secondary: return .capyBrown
            case .skyLight(let base, _): return .white
        }
    }

    var foregroundColor: Color {
        switch self {
            case .primary: return .capyBrown
            case .secondary: return .capyBeige
            case .skyLight: return .black
        }
    }
    
    var overlayImage: String? {
        switch self {
            case .skyLight(_, let overlay): return overlay
            default: return nil
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
        .background {
            ZStack {
                style.backgroundColor
                
                if let img = style.overlayImage {
                    Image(img)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .opacity(0.4)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
    
//    @ViewBuilder
//    private var backgroundView: some View {
//        switch style {
//            case .primary, .secondary:
//                style.backgroundColor
//        }
//        
//    case .imageBackground(let name):
//        Image(name)
//            .resizable()
//            .scaledtoFill()
//    }
}

#Preview {
    VStack(spacing: 16) {
        CapyButton(title: "Continue", action: {})
        CapyButton(title: "Agree", style: .secondary, action: {})
    }
    .padding()
    .background(Color.capyBlue)
}
