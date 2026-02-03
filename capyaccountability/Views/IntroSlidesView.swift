import SwiftUI

struct IntroSlidesView: View {
    var onFinish: () -> Void

    @State private var index = 0

    private let messages = [
        "getting there is important",
        "we are here to help you",
        "getting to your goals means having more $$$",
        "more $$$ means that you can spend them on food, clothes and experiences for capy",
        "but...",
        "if you don't get to your goals on time"
    ]

    var body: some View {
        ZStack {
            CapyBackgroundView(imageName: "wallpaper")

            VStack(spacing: 24) {
                Spacer()

                Text(messages[index])
                    .font(.custom("Gaegu-Regular", size: 30))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                CapyButton(title: buttonTitle, style: .secondary, action: advance)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
    }

    private var buttonTitle: String {
        index == messages.count - 1 ? "Continue" : "Next"
    }

    private func advance() {
        if index < messages.count - 1 {
            index += 1
        } else {
            onFinish()
        }
    }
}

#Preview {
    IntroSlidesView(onFinish: {})
}
