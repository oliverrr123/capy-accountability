import SwiftUI

struct HomeView: View {
    let name: String
    let goals: String

    private let todayTasks = [
        "pick your top 3 tasks",
        "start your first focus block",
        "log progress with capy"
    ]

    var body: some View {
        ZStack {
            CapyBackgroundView()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    todayFocusCard
                    goalsCard
                    rewardsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("hey \(displayName)")
                .font(.custom("CherryBombOne-Regular", size: 40))
                .foregroundStyle(.white)
                .shadow(color: .skyBlue.opacity(0.6), radius: 8, x: 0, y: 2)

            Text("ready to crush it today?")
                .font(.custom("Gaegu-Regular", size: 22))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
    }

    private var todayFocusCard: some View {
        card(title: "today's focus") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(todayTasks, id: \.self) { task in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.capyBrown)
                            .frame(width: 8, height: 8)
                            .padding(.top, 8)
                        Text(task)
                            .font(.custom("Gaegu-Regular", size: 22))
                            .foregroundStyle(Color.capyBrown)
                    }
                }
            }

            CapyButton(title: "Check in", style: .secondary) {
                print("Check in tapped")
            }

            HStack(spacing: 10) {
                quickActionButton(title: "Add task") {
                    print("Add task tapped")
                }
                quickActionButton(title: "Talk to Capy") {
                    print("Talk to Capy tapped")
                }
            }
        }
    }

    private var goalsCard: some View {
        card(title: "goal progress") {
            if goalItems.isEmpty {
                Text("Add your first goal to get started")
                    .font(.custom("Gaegu-Regular", size: 22))
                    .foregroundStyle(Color.capyBrown.opacity(0.8))
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 100), spacing: 10)],
                    alignment: .leading,
                    spacing: 10
                ) {
                    ForEach(displayedGoalItems, id: \.self) { item in
                        chip(text: item)
                    }

                    if extraGoalCount > 0 {
                        chip(text: "+\(extraGoalCount) more")
                    }
                }
            }
        }
    }

    private var rewardsCard: some View {
        card(title: "capy care & rewards") {
            HStack(alignment: .top, spacing: 14) {
                Image("capy_sit")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)

                VStack(alignment: .leading, spacing: 6) {
                    Text("capy mood: motivated")
                        .font(.custom("Gaegu-Regular", size: 22))
                        .foregroundStyle(Color.capyBrown)
                    Text("reward balance: 120 treats")
                        .font(.custom("Gaegu-Regular", size: 20))
                        .foregroundStyle(Color.capyBrown.opacity(0.85))
                }

                Spacer()
            }

            CapyButton(title: "Open rewards", style: .primary) {
                print("Open rewards tapped")
            }
        }
    }

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.custom("Gaegu-Regular", size: 26))
                .foregroundStyle(Color.capyBrown)

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.capyBeige.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func quickActionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Gaegu-Regular", size: 18))
                .foregroundStyle(Color.capyBrown)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
        }
        .background(Color.capyBrown.opacity(0.12))
        .clipShape(Capsule())
    }

    private func chip(text: String) -> some View {
        Text(text)
            .font(.custom("Gaegu-Regular", size: 18))
            .foregroundStyle(Color.capyBrown)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.8))
            .clipShape(Capsule())
    }

    private var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "there" : trimmed
    }

    private var goalItems: [String] {
        let trimmed = goals.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var normalized = trimmed
        normalized = normalized.replacingOccurrences(of: "•", with: "\n")
        normalized = normalized.replacingOccurrences(of: "\\s*[-*]\\s+", with: "\n", options: .regularExpression)

        let separators = CharacterSet(charactersIn: ",;\n")
        return normalized
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var displayedGoalItems: [String] {
        Array(goalItems.prefix(5))
    }

    private var extraGoalCount: Int {
        max(goalItems.count - 5, 0)
    }
}

#Preview {
    HomeView(
        name: "Yazide",
        goals: "ship capy app, run 5k, read 12 books, save money, daily journaling"
    )
}
