import SwiftUI

struct ReviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var store: CapyStore
    @State private var selectedPeriod: CapyReviewPeriod = .daily

    private var summary: CapyReviewSummary {
        store.reviewSummary(for: selectedPeriod)
    }

    private var pendingText: String {
        switch selectedPeriod {
        case .daily:
            let pendingDaily = store.tasks.filter { $0.frequency == .daily && !$0.isDone }.count
            return "pending daily: \(pendingDaily)"
        case .weekly:
            let pendingWeekly = store.tasks.filter { $0.frequency == .weekly && !$0.isDone }.count
            let pendingAll = store.tasks.filter { !$0.isDone }.count
            return "pending weekly: \(pendingWeekly) • all pending: \(pendingAll)"
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 6)
                .padding(.top, 8)

            header
            periodPicker
            summaryCards
            progressionSection
            eventsSection

            Spacer(minLength: 8)

            Button {
                dismiss()
            } label: {
                Text("close")
                    .font(.custom("Gaegu-Regular", size: 24))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.capyBlue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background(Color.capyBeige.opacity(0.96))
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("review")
                    .font(.custom("Gaegu-Regular", size: 32))
                    .foregroundStyle(Color.capyDarkBrown)
                Text(summary.title)
                    .font(.custom("Gaegu-Regular", size: 20))
                    .foregroundStyle(Color.capyBrown.opacity(0.75))
            }

            Spacer()

            Text("streak \(store.stats.streak)")
                .font(.custom("Gaegu-Regular", size: 20))
                .foregroundStyle(Color.capyDarkBrown)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.82))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
    }

    private var periodPicker: some View {
        HStack(spacing: 8) {
            ForEach(CapyReviewPeriod.allCases, id: \.self) { period in
                Button {
                    selectedPeriod = period
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(period.rawValue)
                        .font(.custom("Gaegu-Regular", size: 22))
                        .foregroundStyle(selectedPeriod == period ? .white : Color.capyDarkBrown)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedPeriod == period ? Color.capyBlue : Color.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var summaryCards: some View {
        HStack(spacing: 8) {
            reviewMetric(title: "done", value: "\(summary.completedCount)")
            reviewMetric(title: "coins", value: "+\(summary.coinTotal)")
            reviewMetric(title: "xp", value: "+\(summary.xpTotal)")
        }
        .padding(.horizontal, 20)
    }

    private func reviewMetric(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("Gaegu-Regular", size: 26))
                .foregroundStyle(Color.capyDarkBrown)
            Text(title)
                .font(.custom("Gaegu-Regular", size: 18))
                .foregroundStyle(Color.capyBrown.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var progressionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("capy progression")
                    .font(.custom("Gaegu-Regular", size: 24))
                    .foregroundStyle(Color.capyDarkBrown)
                Spacer()
                Text("lvl \(store.progressionLevel)")
                    .font(.custom("Gaegu-Regular", size: 22))
                    .foregroundStyle(Color.capyDarkBrown)
            }

            Text(store.progressionTitle)
                .font(.custom("Gaegu-Regular", size: 20))
                .foregroundStyle(Color.capyBrown.opacity(0.85))

            ProgressView(value: store.progressionToNextLevel)
                .tint(Color.capyBlue)

            Text("xp \(store.xpIntoCurrentLevel)/\(store.xpNeededForNextLevel) to next level • total completions \(store.stats.totalCompletions)")
                .font(.custom("Gaegu-Regular", size: 17))
                .foregroundStyle(Color.capyBrown.opacity(0.78))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(store.unlockedProgressionPerks, id: \.self) { perk in
                        Text(perk)
                            .font(.custom("Gaegu-Regular", size: 17))
                            .foregroundStyle(Color.capyDarkBrown)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
    }

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("completed tasks")
                .font(.custom("Gaegu-Regular", size: 24))
                .foregroundStyle(Color.capyDarkBrown)

            Text(pendingText)
                .font(.custom("Gaegu-Regular", size: 18))
                .foregroundStyle(Color.capyBrown.opacity(0.75))

            if summary.events.isEmpty {
                Text("no completed tasks in this period yet.")
                    .font(.custom("Gaegu-Regular", size: 20))
                    .foregroundStyle(Color.capyBrown.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(summary.events.prefix(20)) { event in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.custom("Gaegu-Regular", size: 20))
                                    .foregroundStyle(Color.capyDarkBrown)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.title)
                                        .font(.custom("Gaegu-Regular", size: 21))
                                        .foregroundStyle(Color.capyDarkBrown)
                                        .lineLimit(2)
                                    Text("+\(event.coinReward) coins • +\(event.xpReward) xp • \(event.frequency.rawValue)")
                                        .font(.custom("Gaegu-Regular", size: 16))
                                        .foregroundStyle(Color.capyBrown.opacity(0.75))
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .frame(maxHeight: 170)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
    }
}

#Preview {
    ReviewSheet(store: CapyStore(loadFromDisk: false))
}
