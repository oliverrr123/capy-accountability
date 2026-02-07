import ActivityKit
import Foundation

enum CapyLiveActivityMode: String, CaseIterable {
    case capyCare
    case accountability
}

enum CapyLiveActivityGoalScope: String, CaseIterable {
    case allGoals
    case otherGoalsOnly
}

extension CapyLiveActivityMode {
    var title: String {
        switch self {
        case .capyCare:
            return "Capy Care"
        case .accountability:
            return "Accountability"
        }
    }

    var shortLabel: String {
        switch self {
        case .capyCare:
            return "care"
        case .accountability:
            return "focus"
        }
    }

    var subtitle: String {
        switch self {
        case .capyCare:
            return "Prioritize feeding and keeping Capy in good shape."
        case .accountability:
            return "Keep long-term goals visible whenever you check your phone."
        }
    }
}

extension CapyLiveActivityGoalScope {
    var title: String {
        switch self {
        case .allGoals:
            return "All goals"
        case .otherGoalsOnly:
            return "Only other goals"
        }
    }

    var subtitle: String {
        switch self {
        case .allGoals:
            return "Show daily goals first, then weekly/monthly/long-term goals."
        case .otherGoalsOnly:
            return "Hide daily goals in Live Activity and show only non-daily goals."
        }
    }
}

struct CapyLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var headline: String
        var focusText: String
        var progressText: String
        var coins: Int
        var isSleeping: Bool
        var mood: String
        var isAway: Bool
        var mode: String
        var goalScope: String
        var needsFood: Bool
        var isDailyPriority: Bool
    }

    var profileName: String
}

struct CapyLiveActivitySnapshot: Equatable {
    var profileName: String
    var headline: String
    var focusText: String
    var progressText: String
    var coins: Int
    var isSleeping: Bool
    var mood: String
    var isAway: Bool
    var mode: String
    var goalScope: String
    var needsFood: Bool
    var isDailyPriority: Bool

    var contentState: CapyLiveActivityAttributes.ContentState {
        CapyLiveActivityAttributes.ContentState(
            headline: headline,
            focusText: focusText,
            progressText: progressText,
            coins: coins,
            isSleeping: isSleeping,
            mood: mood,
            isAway: isAway,
            mode: mode,
            goalScope: goalScope,
            needsFood: needsFood,
            isDailyPriority: isDailyPriority
        )
    }
}
