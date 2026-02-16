import ActivityKit
import Combine
import Foundation

@MainActor
final class CapyLiveActivityManager: ObservableObject {
    private var lastSnapshot: CapyLiveActivityAttributes.ContentState?
    private var currentActivityID: String?

    func sync(enabled: Bool, snapshot: CapyLiveActivityAttributes.ContentState) {
        if !enabled {
            lastSnapshot = nil
            Task {
                await endAllActivities()
            }
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard snapshot != lastSnapshot else { return }

        lastSnapshot = snapshot

        Task {
            await upsertActivity(with: snapshot)
        }
    }

    private func upsertActivity(with snapshot: CapyLiveActivityAttributes.ContentState) async {
        if let activity = activeActivity {
            let content = ActivityContent(state: snapshot, staleDate: Date.now.addingTimeInterval(45 * 60))
            await activity.update(content)
        } else {
            await startActivity(with: snapshot)
        }
    }
    
    private func startActivity(with snapshot: CapyLiveActivityAttributes.ContentState) async {
        let attributes = CapyLiveActivityAttributes(profileName: "Capy")
        
        let content = ActivityContent(state: snapshot, staleDate: Date.now.addingTimeInterval(45 * 60))
        
        do {
            let activity = try Activity<CapyLiveActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentActivityID = activity.id
        } catch {
            print("Failed to start live activity: \(error.localizedDescription)")
        }
    }

    private func endAllActivities() async {
        for activity in Activity<CapyLiveActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivityID = nil
    }
    
    private var activeActivity: Activity<CapyLiveActivityAttributes>? {
        Activity<CapyLiveActivityAttributes>.activities.first
    }
}
