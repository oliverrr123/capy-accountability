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

enum CapyChallengeLength: Int, Codable, CaseIterable, Identifiable {
    case seven = 7
    case fourteen = 14
    case thirty = 30

    var id: Int { rawValue }

    var title: String {
        "\(rawValue)-day"
    }

    var completionBonusCoins: Int {
        switch self {
        case .seven:
            return 120
        case .fourteen:
            return 300
        case .thirty:
            return 800
        }
    }

    var missPenaltyCoins: Int {
        switch self {
        case .seven:
            return 40
        case .fourteen:
            return 90
        case .thirty:
            return 220
        }
    }
}

struct CapyChallengeState: Codable {
    var isActive: Bool
    var length: CapyChallengeLength
    var startedAt: Date?
    var completedCheckIns: Int
    var lastCheckInDate: Date?

    init(
        isActive: Bool = false,
        length: CapyChallengeLength = .seven,
        startedAt: Date? = nil,
        completedCheckIns: Int = 0,
        lastCheckInDate: Date? = nil
    ) {
        self.isActive = isActive
        self.length = length
        self.startedAt = startedAt
        self.completedCheckIns = completedCheckIns
        self.lastCheckInDate = lastCheckInDate
    }
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
    var freezeProtectors: Int
    var lastCompletionDate: Date?
    var lastResetDate: Date?
    var mood: String
    var xp: Int
    var totalCompletions: Int

    enum CodingKeys: String, CodingKey {
        case coins
        case streak
        case freezeProtectors
        case lastCompletionDate
        case lastResetDate
        case mood
        case xp
        case totalCompletions
    }

    init(
        coins: Int = 0,
        streak: Int = 0,
        freezeProtectors: Int = 0,
        lastCompletionDate: Date? = nil,
        lastResetDate: Date? = nil,
        mood: String = "sleepy",
        xp: Int = 0,
        totalCompletions: Int = 0
    ) {
        self.coins = coins
        self.streak = streak
        self.freezeProtectors = freezeProtectors
        self.lastCompletionDate = lastCompletionDate
        self.lastResetDate = lastResetDate
        self.mood = mood
        self.xp = xp
        self.totalCompletions = totalCompletions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coins = try container.decodeIfPresent(Int.self, forKey: .coins) ?? 0
        streak = try container.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        freezeProtectors = try container.decodeIfPresent(Int.self, forKey: .freezeProtectors) ?? 0
        lastCompletionDate = try container.decodeIfPresent(Date.self, forKey: .lastCompletionDate)
        lastResetDate = try container.decodeIfPresent(Date.self, forKey: .lastResetDate)
        mood = try container.decodeIfPresent(String.self, forKey: .mood) ?? "sleepy"
        xp = try container.decodeIfPresent(Int.self, forKey: .xp) ?? 0
        totalCompletions = try container.decodeIfPresent(Int.self, forKey: .totalCompletions) ?? 0
    }
}

struct CapyCompletionEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let taskID: UUID
    let title: String
    let frequency: TaskFrequency
    let coinReward: Int
    let xpReward: Int
    let completedAt: Date

    init(
        id: UUID = UUID(),
        taskID: UUID,
        title: String,
        frequency: TaskFrequency,
        coinReward: Int,
        xpReward: Int,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.taskID = taskID
        self.title = title
        self.frequency = frequency
        self.coinReward = coinReward
        self.xpReward = xpReward
        self.completedAt = completedAt
    }
}

enum CapyReviewPeriod: String, CaseIterable {
    case daily
    case weekly
}

struct CapyReviewSummary {
    let period: CapyReviewPeriod
    let title: String
    let completedCount: Int
    let coinTotal: Int
    let xpTotal: Int
    let events: [CapyCompletionEvent]
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
    var challenge: CapyChallengeState
    var completionHistory: [CapyCompletionEvent]

    init(
        profile: CapyProfile = CapyProfile(),
        goals: UserGoals? = nil,
        tasks: [CapyTask] = [],
        stats: CapyStats = CapyStats(),
        challenge: CapyChallengeState = CapyChallengeState(),
        completionHistory: [CapyCompletionEvent] = []
    ) {
        self.profile = profile
        self.goals = goals
        self.tasks = tasks
        self.stats = stats
        self.challenge = challenge
        self.completionHistory = completionHistory
    }

    enum CodingKeys: String, CodingKey {
        case profile
        case goals
        case tasks
        case stats
        case challenge
        case completionHistory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profile = try container.decodeIfPresent(CapyProfile.self, forKey: .profile) ?? CapyProfile()
        goals = try container.decodeIfPresent(UserGoals.self, forKey: .goals)
        tasks = try container.decodeIfPresent([CapyTask].self, forKey: .tasks) ?? []
        stats = try container.decodeIfPresent(CapyStats.self, forKey: .stats) ?? CapyStats()
        challenge = try container.decodeIfPresent(CapyChallengeState.self, forKey: .challenge) ?? CapyChallengeState()
        completionHistory = try container.decodeIfPresent([CapyCompletionEvent].self, forKey: .completionHistory) ?? []
    }
}
