import ActivityKit
import Foundation

struct CapyLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var focusText: String
        var streak: Int
        var coins: Int
        var challengeStatus: String?
        var warningText: String?
        var isSleeping: Bool
        
        public init(focusText: String, streak: Int, coins: Int, challengeStatus: String? = nil, warningText: String? = nil, isSleeping: Bool) {
            self.focusText = focusText
            self.streak = streak
            self.coins = coins
            self.challengeStatus = challengeStatus
            self.warningText = warningText
            self.isSleeping = isSleeping
        }
    }

    var profileName: String
}
