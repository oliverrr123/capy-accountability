import SwiftUI

struct GoalsInputView: View {
    @Binding var goals: String
    var onContinue: () -> Void
    var onSpeak: () -> Void = {}

    var body: some View {
        ZStack {
            CapyBackgroundView()

            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 60)

                Text("Tell me ur goals")
                    .font(.custom("Gaegu-Regular", size: 32))
                    .foregroundStyle(.white)

                ZStack(alignment: .topLeading) {
                    if goals.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Type your goals here...")
                            .font(.custom("Gaegu-Regular", size: 22))
                            .foregroundStyle(Color.capyBrown.opacity(0.5))
                            .padding(.top, 14)
                            .padding(.leading, 10)
                    }

                    TextEditor(text: $goals)
                        .font(.custom("Gaegu-Regular", size: 22))
                        .foregroundStyle(Color.capyBrown)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                }
                .frame(height: 320)
                .background(Color.capyBeige.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                Button(action: onSpeak) {
                    HStack(spacing: 10) {
                        Image("mic")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                        Text("Speak instead")
                            .font(.custom("Gaegu-Regular", size: 22))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }

                Spacer()

                CapyButton(title: "Continue", style: .secondary, action: onContinue)
                    .padding(.bottom, 28)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    GoalsInputView(goals: .constant(""), onContinue: {})
}
