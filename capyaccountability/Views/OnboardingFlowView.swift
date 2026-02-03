import SwiftUI

struct OnboardingFlowView: View {
    @State private var step: OnboardingStep = .login
    @State private var name = ""
    @State private var goals = ""

    var body: some View {
        ZStack {
            switch step {
            case .login:
                InitialView(onContinue: { advance(to: .name) })
                    .transition(.opacity)
            case .name:
                SpeechView2(name: $name) {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    advance(to: .goals)
                }
                .transition(.opacity)
            case .goals:
                GoalsInputView(goals: $goals, onContinue: { advance(to: .thinking) })
                    .transition(.opacity)
            case .thinking:
                ThinkingView(onComplete: { advance(to: .itinerary) })
                    .transition(.opacity)
            case .itinerary:
                ItineraryView(onContinue: { advance(to: .intro) })
                    .transition(.opacity)
            case .intro:
                IntroSlidesView(onFinish: { advance(to: .final) })
                    .transition(.opacity)
            case .final:
                FinalCTAView(onFinish: resetFlow)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
        .environment(\.font, .custom("Gaegu-Regular", size: 24))
    }

    private func advance(to next: OnboardingStep) {
        withAnimation {
            step = next
        }
    }

    private func resetFlow() {
        name = ""
        goals = ""
        advance(to: .login)
    }
}

#Preview {
    OnboardingFlowView()
}
