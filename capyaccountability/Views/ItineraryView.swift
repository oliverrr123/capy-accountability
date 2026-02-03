import SwiftUI

struct ItineraryView: View {
    var onContinue: () -> Void

    private let items = [
        "set daily goals",
        "check in weekly",
        "track progress monthly",
        "earn capy rewards"
    ]

    var body: some View {
        ZStack {
            CapyBackgroundView()

            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 70)

                Text("your (accountability) itinerary")
                    .font(.custom("Gaegu-Regular", size: 28))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Text("•")
                                .font(.custom("Gaegu-Regular", size: 26))
                                .foregroundStyle(.white)
                            Text(item)
                                .font(.custom("Gaegu-Regular", size: 24))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.capyBeige.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 24)

                Spacer()

                CapyButton(title: "Continue", style: .secondary, action: onContinue)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
    }
}

#Preview {
    ItineraryView(onContinue: {})
}
