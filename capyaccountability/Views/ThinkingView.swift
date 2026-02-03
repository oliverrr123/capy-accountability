import SwiftUI

struct ThinkingView: View {
    var onComplete: () -> Void

    @State private var index = 0
    @State private var hasStarted = false

    private let messages = [
        "capy is thinking (creating your goals)",
        "capy is thinking (creating your plan)",
        "capy is almost there"
    ]

    var body: some View {
        ZStack {
            CapyBackgroundView()

            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 80)

                Text(messages[index])
                    .font(.custom("Gaegu-Regular", size: 28))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()

                Image("capy_sit")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 24)
            }
        }
        .onAppear { startSequenceIfNeeded() }
    }

    private func startSequenceIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        advance()
    }

    private func advance() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if index < messages.count - 1 {
                index += 1
                advance()
            } else {
                onComplete()
            }
        }
    }
}

#Preview {
    ThinkingView(onComplete: {})
}
