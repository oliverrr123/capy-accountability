import ActivityKit
import Foundation

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
