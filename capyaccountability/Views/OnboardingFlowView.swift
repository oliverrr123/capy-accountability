import SwiftUI

struct OnboardingFlowView: View {
    var onFinish: (String, String) -> Void = { _, _ in }

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
                SpeechView2(name: $name, onBack: goBack) {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    advance(to: .mic)
                }
                .transition(.opacity)
            case .mic:
                SpeechView3(name: $name, onBack: goBack) {
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
                FinalCTAView(onFinish: finishOnboarding)
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

    private func finishOnboarding() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGoals = goals.trimmingCharacters(in: .whitespacesAndNewlines)
        onFinish(trimmedName, trimmedGoals)
    }

    private func goBack() {
        withAnimation {
            switch step {
            case .login: break
            case .name: step = .login
            case .mic: step = .name
            case .goals: step = .mic
            case .thinking: step = .goals
            case .itinerary: step = .thinking
            case .intro: step = .itinerary
            case .final: step = .intro
           }
        }
    }
}

#Preview {
    OnboardingFlowView()
}

struct BackButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 60, height: 60)
        }
    }
}
