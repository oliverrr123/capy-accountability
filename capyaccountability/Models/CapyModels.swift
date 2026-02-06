import Foundation

struct UserGoals: Codable {
    let longTerm: [String]
    let decade: [String]
    let yearly: [String]
    let monthly: [String]
    let weekly: [String]
    let daily: [String]

    enum CodingKeys: String, CodingKey {
        case longTerm = "long_term"
        case decade, yearly, monthly, weekly, daily
    }
}

enum TaskFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    case yearly
    case decade
    case longTerm
}

struct CapyTask: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var frequency: TaskFrequency
    var isDone: Bool
    var createdAt: Date
    var completedAt: Date?
    
    var coinReward: Int
    var statReward: String?

    init(
        id: UUID = UUID(),
        title: String,
        frequency: TaskFrequency = .daily,
        isDone: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        coinReward: Int = 10,
        statReward: String? = nil
    ) {
        self.id = id
        self.title = title
        self.frequency = frequency
        self.isDone = isDone
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.coinReward = coinReward
        self.statReward = statReward
    }
}

struct CapyStats: Codable {
    var coins: Int
    var streak: Int
    var lastCompletionDate: Date?
    var lastResetDate: Date?
    var mood: String

    init(coins: Int = 0, streak: Int = 0, lastCompletionDate: Date? = nil, lastResetDate: Date? = nil, mood: String = "sleepy") {
        self.coins = coins
        self.streak = streak
        self.lastCompletionDate = lastCompletionDate
        self.lastResetDate = lastResetDate
        self.mood = mood
    }
}

struct CapyProfile: Codable {
    var name: String
    var goalsText: String

    init(name: String = "", goalsText: String = "") {
        self.name = name
        self.goalsText = goalsText
    }
}

struct CapyStoreState: Codable {
    var profile: CapyProfile
    var goals: UserGoals?
    var tasks: [CapyTask]
    var stats: CapyStats

    init(profile: CapyProfile = CapyProfile(), goals: UserGoals? = nil, tasks: [CapyTask] = [], stats: CapyStats = CapyStats()) {
        self.profile = profile
        self.goals = goals
        self.tasks = tasks
        self.stats = stats
    }
}
