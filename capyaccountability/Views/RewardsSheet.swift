import SwiftUI
import UIKit

struct RewardItem: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let cost: Int
    let description: String
}

struct RewardsSheet: View {
    @EnvironmentObject private var store: CapyStore
    @Environment(\.dismiss) private var dismiss

    @State private var showAlert = false
    @State private var alertMessage = ""

    private let items: [RewardItem] = [
        RewardItem(emoji: "🍡", title: "Capy snack", cost: 25, description: "Sweet treat for a focused day"),
        RewardItem(emoji: "🛁", title: "Hot spring soak", cost: 40, description: "Relaxing bath time"),
        RewardItem(emoji: "🎧", title: "Music break", cost: 30, description: "10 min of your favorite music"),
        RewardItem(emoji: "🌿", title: "Nature walk", cost: 50, description: "Refresh outside with Capy")
    ]

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 6)
                .padding(.top, 8)

            HStack {
                Text("Rewards")
                    .font(.custom("Gaegu-Regular", size: 30))
                Spacer()
                Text("🪙 \(store.stats.coins)")
                    .font(.custom("Gaegu-Regular", size: 22))
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                ForEach(items) { item in
                    rewardRow(item)
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            CapyButton(title: "Close", style: .secondary) {
                dismiss()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.capyBeige.opacity(0.9))
        .alert("Reward", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func rewardRow(_ item: RewardItem) -> some View {
        HStack(spacing: 14) {
            Text(item.emoji)
                .font(.system(size: 30))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.custom("Gaegu-Regular", size: 22))
                Text(item.description)
                    .font(.custom("Gaegu-Regular", size: 16))
                    .foregroundStyle(Color.capyBrown.opacity(0.7))
            }

            Spacer()

            Button(action: { redeem(item) }) {
                Text("\(item.cost)")
                    .font(.custom("Gaegu-Regular", size: 20))
                    .foregroundStyle(Color.capyBrown)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func redeem(_ item: RewardItem) {
        if store.spendCoins(item.cost) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            alertMessage = "Redeemed \(item.title)!"
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            alertMessage = "Not enough coins yet. Finish more tasks!"
        }
        showAlert = true
    }
}

#Preview {
    RewardsSheet()
        .environmentObject(CapyStore.preview)
}
