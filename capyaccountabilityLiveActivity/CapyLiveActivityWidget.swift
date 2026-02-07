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
                    StatusPillView(context: context)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("🪙 \(context.state.coins)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.white)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.focusText)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(context.state.progressText)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
            } compactLeading: {
                Image(systemName: compactLeadingSymbol(for: context))
                    .foregroundStyle(compactLeadingColor(for: context))
            } compactTrailing: {
                Text("\(context.state.coins)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white)
            } minimal: {
                Text("🪙")
            }
            .keylineTint(.white)
        }
    }
}

private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<CapyLiveActivityAttributes>

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.13, blue: 0.2),
                    Color(red: 0.12, green: 0.18, blue: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    ModeTagView(context: context)
                    StatusPillView(context: context)
                    Spacer()
                    Text("🪙 \(context.state.coins)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.white)
                }

                Text(context.state.focusText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack {
                    Text(context.state.progressText)
                    Spacer()
                    Text(footerText(for: context))
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.82))
            }
            .padding(16)
        }
    }
}

private struct StatusPillView: View {
    let context: ActivityViewContext<CapyLiveActivityAttributes>

    private var indicatorColor: Color {
        if context.state.isSleeping {
            return .blue
        }
        switch context.state.mood {
        case "proud":
            return .green
        case "focused":
            return .mint
        default:
            return .orange
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 8, height: 8)
            Text(context.state.headline)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct ModeTagView: View {
    let context: ActivityViewContext<CapyLiveActivityAttributes>

    private var modeLabel: String {
        context.state.mode == "capyCare" ? "care" : "focus"
    }

    var body: some View {
        Text(modeLabel)
            .font(.caption2.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.white.opacity(0.16))
            .clipShape(Capsule())
    }
}

private func compactLeadingSymbol(for context: ActivityViewContext<CapyLiveActivityAttributes>) -> String {
    if context.state.isSleeping {
        return "moon.fill"
    }
    if context.state.mode == "capyCare" {
        return context.state.needsFood ? "fork.knife.circle.fill" : "heart.circle.fill"
    }
    return context.state.isDailyPriority ? "calendar.circle.fill" : "target"
}

private func compactLeadingColor(for context: ActivityViewContext<CapyLiveActivityAttributes>) -> Color {
    if context.state.isSleeping {
        return .blue
    }
    if context.state.mode == "capyCare" {
        return context.state.needsFood ? .orange : .green
    }
    return context.state.isDailyPriority ? .mint : .cyan
}

private func footerText(for context: ActivityViewContext<CapyLiveActivityAttributes>) -> String {
    if context.state.isAway {
        return "Away"
    }
    if context.state.goalScope == "otherGoalsOnly" {
        return "Other goals"
    }
    return "All goals"
}

@main
struct CapyLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        CapyLiveActivityWidget()
    }
}
