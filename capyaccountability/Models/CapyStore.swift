import Foundation
import SwiftUI
import Combine

struct CapyTaskToggleResult {
    let challengeMessage: String?
}

final class CapyStore: ObservableObject {
    @Published private(set) var profile: CapyProfile
    @Published private(set) var goals: UserGoals?
    @Published private(set) var tasks: [CapyTask]
    @Published private(set) var stats: CapyStats
    @Published private(set) var challenge: CapyChallengeState
    @Published private(set) var completionHistory: [CapyCompletionEvent]

    private let storageKey = "capy_store_state_v1"
    private let calendar = Calendar.current
    static let freezeProtectorCost = 48

    init(loadFromDisk: Bool = true) {
        self.profile = CapyProfile()
        self.goals = nil
        self.tasks = []
        self.stats = CapyStats()
        self.challenge = CapyChallengeState()
        self.completionHistory = []

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
            challenge = decoded.challenge
            completionHistory = decoded.completionHistory
        } catch {
            print("Failed to load CapyStore: \(error)")
        }
    }

    func save() {
        let state = CapyStoreState(
            profile: profile,
            goals: goals,
            tasks: tasks,
            stats: stats,
            challenge: challenge,
            completionHistory: completionHistory
        )
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

    @discardableResult
    func toggleTask(_ task: CapyTask) -> CapyTaskToggleResult {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            return CapyTaskToggleResult(challengeMessage: nil)
        }
        let oldCompletedAt = tasks[index].completedAt
        var challengeMessage: String?
        tasks[index].isDone.toggle()
        if tasks[index].isDone {
            let completedAt = Date()
            tasks[index].completedAt = completedAt
            stats.coins += tasks[index].coinReward
            let gainedXP = xpReward(for: tasks[index].frequency)
            stats.xp += gainedXP
            stats.totalCompletions += 1
            appendCompletionEvent(for: tasks[index], xpReward: gainedXP, at: completedAt)
            challengeMessage = recordDailyCompletionIfNeeded(now: completedAt)
        } else {
            tasks[index].completedAt = nil
            stats.coins = max(stats.coins - tasks[index].coinReward, 0)
            let revertedXP = xpReward(for: tasks[index].frequency)
            stats.xp = max(stats.xp - revertedXP, 0)
            stats.totalCompletions = max(stats.totalCompletions - 1, 0)
            removeCompletionEvent(taskID: tasks[index].id, completedAt: oldCompletedAt)
        }
        updateMood()
        save()
        return CapyTaskToggleResult(challengeMessage: challengeMessage)
    }

    func spendCoins(_ amount: Int) -> Bool {
        guard amount > 0, stats.coins >= amount else { return false }
        stats.coins -= amount
        save()
        return true
    }

    func awardBonusCoins(_ amount: Int) {
        guard amount > 0 else { return }
        stats.coins += amount
        save()
    }

    @discardableResult
    func resetDailyIfNeeded(now: Date = Date()) -> [String] {
        let today = calendar.startOfDay(for: now)
        if let lastReset = stats.lastResetDate, calendar.isDate(lastReset, inSameDayAs: today) {
            return []
        }

        var messages: [String] = []

        if let challengePenalty = evaluateChallengeMissIfNeeded(on: today) {
            messages.append(challengePenalty)
        }
        if let freezeMessage = applyFreezeProtectionIfNeeded(on: today) {
            messages.append(freezeMessage)
        }

        for index in tasks.indices {
            if tasks[index].frequency == .daily {
                tasks[index].isDone = false
                tasks[index].completedAt = nil
            }
        }

        stats.lastResetDate = now
        updateMood()
        save()
        return messages
    }

    func startChallenge(_ length: CapyChallengeLength, now: Date = Date()) {
        challenge = CapyChallengeState(
            isActive: true,
            length: length,
            startedAt: calendar.startOfDay(for: now),
            completedCheckIns: 0,
            lastCheckInDate: nil
        )
        save()
    }

    func buyFreezeProtector() -> Bool {
        guard stats.coins >= Self.freezeProtectorCost else { return false }
        stats.coins -= Self.freezeProtectorCost
        stats.freezeProtectors += 1
        save()
        return true
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

    var progressionLevel: Int {
        progressionState.level
    }

    var xpIntoCurrentLevel: Int {
        progressionState.xpIntoLevel
    }

    var xpNeededForNextLevel: Int {
        progressionState.xpNeededForNextLevel
    }

    var progressionToNextLevel: Double {
        guard progressionState.xpNeededForNextLevel > 0 else { return 0 }
        return min(
            max(Double(progressionState.xpIntoLevel) / Double(progressionState.xpNeededForNextLevel), 0),
            1
        )
    }

    var progressionTitle: String {
        switch progressionLevel {
        case 1...2: return "tiny capy"
        case 3...4: return "focused capy"
        case 5...7: return "river captain"
        case 8...11: return "hot spring legend"
        default: return "goal guardian"
        }
    }

    var unlockedProgressionPerks: [String] {
        var perks: [String] = ["lvl 1: capy badge"]
        if progressionLevel >= 3 { perks.append("lvl 3: combo bonus glow") }
        if progressionLevel >= 5 { perks.append("lvl 5: river captain title") }
        if progressionLevel >= 8 { perks.append("lvl 8: hot spring aura") }
        if progressionLevel >= 12 { perks.append("lvl 12: goal guardian title") }
        return perks
    }

    func reviewSummary(for period: CapyReviewPeriod, now: Date = Date()) -> CapyReviewSummary {
        let filteredEvents = events(for: period, now: now)
        let title: String

        switch period {
        case .daily:
            title = "today"
        case .weekly:
            title = "this week"
        }

        return CapyReviewSummary(
            period: period,
            title: title,
            completedCount: filteredEvents.count,
            coinTotal: filteredEvents.reduce(0) { $0 + $1.coinReward },
            xpTotal: filteredEvents.reduce(0) { $0 + $1.xpReward },
            events: filteredEvents
        )
    }

    private var progressionState: (level: Int, xpIntoLevel: Int, xpNeededForNextLevel: Int) {
        var level = 1
        var remainingXP = max(stats.xp, 0)
        var needed = xpNeededToAdvance(from: level)

        while remainingXP >= needed {
            remainingXP -= needed
            level += 1
            needed = xpNeededToAdvance(from: level)
        }

        return (level, remainingXP, needed)
    }

    private func xpNeededToAdvance(from level: Int) -> Int {
        80 + ((max(level, 1) - 1) * 20)
    }

    private func xpReward(for frequency: TaskFrequency) -> Int {
        switch frequency {
        case .daily: return 12
        case .weekly: return 26
        case .monthly: return 40
        case .yearly: return 75
        case .decade: return 110
        case .longTerm: return 140
        }
    }

    private func appendCompletionEvent(for task: CapyTask, xpReward: Int, at completedAt: Date) {
        let event = CapyCompletionEvent(
            taskID: task.id,
            title: task.title,
            frequency: task.frequency,
            coinReward: task.coinReward,
            xpReward: xpReward,
            completedAt: completedAt
        )
        completionHistory.append(event)

        let maxEvents = 1000
        if completionHistory.count > maxEvents {
            completionHistory.removeFirst(completionHistory.count - maxEvents)
        }
    }

    private func removeCompletionEvent(taskID: UUID, completedAt: Date?) {
        guard let completedAt else { return }
        let graceWindow: TimeInterval = 5

        if let index = completionHistory.lastIndex(where: {
            $0.taskID == taskID &&
            abs($0.completedAt.timeIntervalSince(completedAt)) <= graceWindow
        }) {
            completionHistory.remove(at: index)
        }
    }

    private func events(for period: CapyReviewPeriod, now: Date) -> [CapyCompletionEvent] {
        switch period {
        case .daily:
            return completionHistory
                .filter { calendar.isDate($0.completedAt, inSameDayAs: now) }
                .sorted { $0.completedAt > $1.completedAt }
        case .weekly:
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
                return []
            }
            return completionHistory
                .filter { weekInterval.contains($0.completedAt) }
                .sorted { $0.completedAt > $1.completedAt }
        }
    }

    private func recordDailyCompletionIfNeeded(now: Date) -> String? {
        guard allDailyComplete else { return nil }
        let today = calendar.startOfDay(for: now)

        if let lastCompletion = stats.lastCompletionDate {
            let lastDay = calendar.startOfDay(for: lastCompletion)
            if calendar.isDate(lastDay, inSameDayAs: today) {
                return nil
            }
            if let expected = calendar.date(byAdding: .day, value: 1, to: lastDay), calendar.isDate(expected, inSameDayAs: today) {
                stats.streak += 1
            } else {
                stats.streak = 1
            }
        } else {
            stats.streak = 1
        }

        stats.lastCompletionDate = now
        return recordChallengeCheckInIfNeeded(on: today)
    }

    private func applyFreezeProtectionIfNeeded(on today: Date) -> String? {
        guard let lastCompletion = stats.lastCompletionDate else { return nil }
        let lastDay = calendar.startOfDay(for: lastCompletion)
        let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
        let missedDays = max(daysBetween - 1, 0)
        guard missedDays > 0 else { return nil }

        let protectorsUsed = min(stats.freezeProtectors, missedDays)
        if protectorsUsed > 0 {
            stats.freezeProtectors -= protectorsUsed
            if let bridged = calendar.date(byAdding: .day, value: protectorsUsed, to: lastDay) {
                stats.lastCompletionDate = bridged
            }
        }

        if protectorsUsed >= missedDays {
            return "freeze protector saved your streak. used \(protectorsUsed), \(stats.freezeProtectors) left."
        }

        stats.streak = 0
        if protectorsUsed > 0 {
            return "used \(protectorsUsed) freeze protector, but streak still broke."
        }
        return nil
    }

    private func evaluateChallengeMissIfNeeded(on today: Date) -> String? {
        guard challenge.isActive, let startedAt = challenge.startedAt else { return nil }
        let startDay = calendar.startOfDay(for: startedAt)
        guard today > startDay else { return nil }
        guard let requiredCheckInDay = calendar.date(byAdding: .day, value: -1, to: today) else { return nil }

        guard let lastCheckIn = challenge.lastCheckInDate else {
            return failActiveChallenge()
        }

        let lastCheckInDay = calendar.startOfDay(for: lastCheckIn)
        if lastCheckInDay < requiredCheckInDay {
            return failActiveChallenge()
        }

        return nil
    }

    private func recordChallengeCheckInIfNeeded(on day: Date) -> String? {
        guard challenge.isActive, let startedAt = challenge.startedAt else { return nil }
        let startDay = calendar.startOfDay(for: startedAt)
        guard day >= startDay else { return nil }

        if let lastCheckIn = challenge.lastCheckInDate {
            let lastDay = calendar.startOfDay(for: lastCheckIn)
            if calendar.isDate(lastDay, inSameDayAs: day) {
                return nil
            }
            if let expected = calendar.date(byAdding: .day, value: 1, to: lastDay), !calendar.isDate(expected, inSameDayAs: day) {
                return failActiveChallenge()
            }
        } else if day > startDay {
            return failActiveChallenge()
        }

        challenge.lastCheckInDate = day
        challenge.completedCheckIns += 1

        if challenge.completedCheckIns >= challenge.length.rawValue {
            let bonus = challenge.length.completionBonusCoins
            let completedTitle = challenge.length.title
            stats.coins += bonus
            challenge = CapyChallengeState()
            return "challenge \(completedTitle) complete! +\(bonus) coins."
        }

        return "challenge day \(challenge.completedCheckIns)/\(challenge.length.rawValue) locked in."
    }

    private func failActiveChallenge() -> String? {
        guard challenge.isActive else { return nil }
        let penalty = challenge.length.missPenaltyCoins
        let challengeTitle = challenge.length.title
        stats.coins = max(stats.coins - penalty, 0)
        challenge = CapyChallengeState()
        return "missed a day. \(challengeTitle) challenge failed: -\(penalty) coins."
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
