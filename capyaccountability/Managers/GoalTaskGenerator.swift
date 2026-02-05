import Foundation

struct GoalTaskGenerator {
    func generate(from goals: UserGoals, maxTasks: Int = 8) -> [CapyTask] {
        var tasks: [CapyTask] = []

        tasks.append(contentsOf: goals.daily.prefix(3).map { CapyTask(title: normalize($0), frequency: .daily) })
        tasks.append(contentsOf: goals.weekly.prefix(3).map { CapyTask(title: normalize($0), frequency: .weekly) })
        tasks.append(contentsOf: goals.monthly.prefix(2).map { CapyTask(title: normalize($0), frequency: .monthly) })

        if tasks.count < maxTasks {
            tasks.append(contentsOf: goals.yearly.prefix(2).map { CapyTask(title: "Move forward on \(normalize($0))", frequency: .weekly) })
        }
        if tasks.count < maxTasks {
            tasks.append(contentsOf: goals.longTerm.prefix(1).map { CapyTask(title: "Plan \(normalize($0))", frequency: .monthly) })
        }
        if tasks.count < maxTasks {
            tasks.append(contentsOf: goals.decade.prefix(1).map { CapyTask(title: "Step toward \(normalize($0))", frequency: .monthly) })
        }

        if tasks.isEmpty {
            tasks = [
                CapyTask(title: "Pick 3 focus tasks", frequency: .daily),
                CapyTask(title: "Do one deep work block", frequency: .daily),
                CapyTask(title: "Plan tomorrow", frequency: .daily)
            ]
        }

        return Array(tasks.prefix(maxTasks))
    }

    private func normalize(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "your goal" : trimmed
    }
}
