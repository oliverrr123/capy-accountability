import ActivityKit
import SwiftUI
import WidgetKit

struct CapyLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CapyLiveActivityAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.9))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        if let warning = context.state.warningText {
                            Text(warning)
                                .font(.caption.bold()).foregroundStyle(.orange)
                        } else {
                            Text("🔥 \(context.state.streak)").font(.headline)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    if let challenge = context.state.challengeStatus {
                        Text("🎯 \(challenge)")
                    } else {
                        Text("🪙 \(context.state.coins)")
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.focusText)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            } compactLeading: {
                if context.state.isSleeping {
                    Image(systemName: "moon.fill").foregroundStyle(.blue)
                } else if context.state.warningText != nil {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                } else {
                    Text("🔥 \(context.state.streak)")
                }
            } compactTrailing: {
                if let challenge = context.state.challengeStatus {
                    Text("🎯\(challenge)")
                } else {
                    Text("\(context.state.coins)")
                }
            } minimal: {
                Text("🔥")
            }
        }
    }
}

private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<CapyLiveActivityAttributes>

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .center, spacing: 2) {
                if context.state.isSleeping {
                    Text("💤").font(.title2)
                    Text("Sleep").font(.caption2).opacity(0.7)
                } else if let warning = context.state.warningText {
                    Text(warning)
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                } else {
                    Text("🔥 \(context.state.streak)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Streak")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(width: 60)
            
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(width: 1)
                .padding(.vertical, 8)
            
            VStack(alignment: .leading) {
                Text("CURRENT GOAL")
                    .font(.caption2.bold())
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                
                Text(context.state.focusText)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if context.state.challengeStatus != nil {
                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 1)
                    .padding(.vertical, 8)
            }
            
            if let challenge = context.state.challengeStatus {
                VStack(alignment: .center, spacing: 2) {
                    Text("🎯")
                        .font(.system(size: 18))
                    Text(challenge)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 60)
            } else {
                VStack(alignment: .center, spacing: 2) {
                    Text("🪙")
                        .font(.caption)
                    Text("\(context.state.coins)")
                        .font(.caption.bold())
                }
                .frame(width: 50)
                .opacity(0.6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.12), .black],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

@main
struct CapyLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        CapyLiveActivityWidget()
    }
}
