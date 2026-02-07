import ActivityKit
import Combine
import Foundation

@MainActor
final class CapyLiveActivityManager: ObservableObject {
    private var lastSnapshot: CapyLiveActivitySnapshot?
    private var currentActivityID: String?

    func sync(enabled: Bool, snapshot: CapyLiveActivitySnapshot) {
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

    private func upsertActivity(with snapshot: CapyLiveActivitySnapshot) async {
        if let activity = activeActivity {
            let content = ActivityContent(state: snapshot.contentState, staleDate: Date.now.addingTimeInterval(45 * 60))
            await activity.update(content)
            return
        }

        let attributes = CapyLiveActivityAttributes(profileName: snapshot.profileName)
        let content = ActivityContent(state: snapshot.contentState, staleDate: Date.now.addingTimeInterval(45 * 60))

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

    private var activeActivity: Activity<CapyLiveActivityAttributes>? {
        let activities = Activity<CapyLiveActivityAttributes>.activities

        if let currentActivityID,
           let matching = activities.first(where: { $0.id == currentActivityID }) {
            return matching
        }

        let fallback = activities.first
        currentActivityID = fallback?.id
        return fallback
    }

    private func endAllActivities() async {
        let activities = Activity<CapyLiveActivityAttributes>.activities
        for activity in activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivityID = nil
    }
}
