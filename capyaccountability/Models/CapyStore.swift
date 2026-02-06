import Foundation
import SwiftUI
import Combine

final class CapyStore: ObservableObject {
    @Published private(set) var profile: CapyProfile
    @Published private(set) var goals: UserGoals?
    @Published private(set) var tasks: [CapyTask]
    @Published private(set) var stats: CapyStats

    private let storageKey = "capy_store_state_v1"
    private let calendar = Calendar.current

    init(loadFromDisk: Bool = true) {
        self.profile = CapyProfile()
        self.goals = nil
        self.tasks = []
        self.stats = CapyStats()

        if loadFromDisk {
            load()
            resetDailyIfNeeded()
        }
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode(CapyStoreState.self, from: data)
            profile = decoded.profile
            goals = decoded.goals
            tasks = decoded.tasks
            stats = decoded.stats
        } catch {
            print("Failed to load CapyStore: \(error)")
        }
    }

    func save() {
        let state = CapyStoreState(profile: profile, goals: goals, tasks: tasks, stats: stats)
        do {
            let data = try JSONEncoder().encode(state)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save CapyStore: \(error)")
        }
    }

    func updateProfile(name: String, goalsText: String) {
        profile = CapyProfile(name: name, goalsText: goalsText)
        save()
    }

    func updateGoals(_ goals: UserGoals?) {
        self.goals = goals
        save()
    }

    func setTasks(_ newTasks: [CapyTask]) {
        tasks = newTasks
        updateMood()
        save()
    }

    func addTask(title: String, frequency: TaskFrequency = .daily) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let (coins, stat) = calculateRewards(for: frequency)
        
        let newTask = CapyTask(
            title: trimmed,
            frequency: frequency,
            coinReward: coins,
            statReward: stat
        )
        
        tasks.append(newTask)
        updateMood()
        save()
    }
    
    private func calculateRewards(for freq: TaskFrequency) -> (Int, String) {
        switch freq {
        case .daily: return (10, "😁")
        case .weekly: return (30, "🍋")
        case .monthly: return (50, "🛁")
        case .yearly: return (200, "😁")
        case .decade: return (500, "🍋")
        case .longTerm: return (1000, "🛁")
        }
    }

    func deleteTask(_ task: CapyTask) {
        tasks.removeAll { $0.id == task.id }
        updateMood()
        save()
    }

    func toggleTask(_ task: CapyTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        let wasDone = tasks[index].isDone
        tasks[index].isDone.toggle()
        if tasks[index].isDone {
            tasks[index].completedAt = Date()
            if !wasDone {
                applyCompletionRewards(for: tasks[index])
                recordDailyCompletionIfNeeded()
            }
        } else {
            tasks[index].completedAt = nil
        }
        updateMood()
        save()
    }

    func spendCoins(_ amount: Int) -> Bool {
        guard amount > 0, stats.coins >= amount else { return false }
        stats.coins -= amount
        save()
        return true
    }

    func resetDailyIfNeeded() {
        let today = calendar.startOfDay(for: Date())
        if let lastReset = stats.lastResetDate, calendar.isDate(lastReset, inSameDayAs: today) {
            return
        }

        for index in tasks.indices {
            if tasks[index].frequency == .daily {
                tasks[index].isDone = false
                tasks[index].completedAt = nil
            }
        }

        stats.lastResetDate = Date()
        if let lastCompletion = stats.lastCompletionDate {
            let lastDay = calendar.startOfDay(for: lastCompletion)
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), lastDay < yesterday {
                stats.streak = 0
            }
        }
        updateMood()
        save()
    }

    var completionRatio: Double {
        guard !tasks.isEmpty else { return 0 }
        let done = tasks.filter { $0.isDone }.count
        return Double(done) / Double(tasks.count)
    }

    var dailyCompletionRatio: Double {
        let daily = tasks.filter { $0.frequency == .daily }
        guard !daily.isEmpty else { return 0 }
        let done = daily.filter { $0.isDone }.count
        return Double(done) / Double(daily.count)
    }

    var allDailyComplete: Bool {
        let daily = tasks.filter { $0.frequency == .daily }
        return !daily.isEmpty && daily.allSatisfy { $0.isDone }
    }

    private func applyCompletionRewards(for task: CapyTask) {
        stats.coins += rewardValue(for: task.frequency)
    }

    private func rewardValue(for frequency: TaskFrequency) -> Int {
        switch frequency {
        case .daily: return 5
        case .weekly: return 10
        case .monthly: return 20
        case .yearly: return 40
        case .decade: return 60
        case .longTerm: return 30
        }
    }

    private func recordDailyCompletionIfNeeded() {
        guard allDailyComplete else { return }
        let today = calendar.startOfDay(for: Date())

        if let lastCompletion = stats.lastCompletionDate {
            let lastDay = calendar.startOfDay(for: lastCompletion)
            if calendar.isDate(lastDay, inSameDayAs: today) {
                return
            }
            if let expected = calendar.date(byAdding: .day, value: 1, to: lastDay), calendar.isDate(expected, inSameDayAs: today) {
                stats.streak += 1
            } else {
                stats.streak = 1
            }
        } else {
            stats.streak = 1
        }

        stats.lastCompletionDate = Date()
    }

    private func updateMood() {
        let ratio = max(dailyCompletionRatio, completionRatio)
        switch ratio {
        case 0..<0.34:
            stats.mood = "sleepy"
        case 0.34..<0.67:
            stats.mood = "focused"
        case 0.67...1:
            stats.mood = "proud"
        default:
            stats.mood = "sleepy"
        }
    }
}

//extension CapyStore {
//    static var preview: CapyStore {
//        let store = CapyStore(loadFromDisk: false)
//        store.updateProfile(name: "Yazide", goalsText: "ship capy app, run 5k, read 12 books")
//        store.updateGoals(nil)
//        store.setTasks([
//            CapyTask(title: "Wake up early", frequency: .daily, isDone: true),
//            CapyTask(title: "Finish Capy MVP", frequency: .weekly, isDone: false),
//            CapyTask(title: "Run 3km", frequency: .daily, isDone: false)
//        ])
//        store.stats = CapyStats(coins: 420, streak: 3, mood: "focused")
//        return store
//    }
//}

extension CapyStore {
    func generateTasks(from aiGoals: UserGoals) {
        self.updateGoals(aiGoals)
        
        var newTasks: [CapyTask] = []
        
        func add(_ title: String, _ freq: TaskFrequency) {
            let (coins, stat) = self.calculateRewards(for: freq)
            
            newTasks.append(CapyTask(title: title, frequency: freq, coinReward: coins, statReward: stat))
        }
        
        for goal in aiGoals.daily { add(goal, .daily) }
        for goal in aiGoals.weekly { add(goal, .weekly) }
        for goal in aiGoals.monthly { add(goal, .monthly) }
        for goal in aiGoals.yearly { add(goal, .yearly) }
        for goal in aiGoals.decade { add(goal, .decade) }
        for goal in aiGoals.longTerm { add(goal, .longTerm) }
        
        DispatchQueue.main.async {
            self.setTasks(newTasks)
            print("CapyStore Saved \(newTasks.count) tasks")
        }
    }
}
