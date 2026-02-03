import SwiftUI

struct FinalCTAView: View {
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            CapyBackgroundView()

            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 80)

                Text("you will be accountable for it")
                    .font(.custom("Gaegu-Regular", size: 30))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Spacer()

                Image("Capy")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320)
                    .padding(.horizontal, 40)

                Spacer()

                CapyButton(title: "Agree", style: .secondary, action: onFinish)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
    }
}

#Preview {
    FinalCTAView(onFinish: {})
}
