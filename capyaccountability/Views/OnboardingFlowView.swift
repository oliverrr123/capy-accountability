import SwiftUI

struct OnboardingFlowView: View {
    var onFinish: (String, String) -> Void = { _, _ in }

    @State private var step: OnboardingStep = .login
    @State private var name = ""
    
//    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var store: CapyStore

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
                SpeechView3(
                    name: $name,
                    onBack: goBack,
                    onSubmit: {
                        onFinish(name, "")
                        advance(to: .home)
                    },
                    store: store
//                    viewModel: taskViewModel
                )
                .transition(.opacity)
            case .home:
                HomeView2(store: store)
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

    private func goBack() {
        withAnimation {
            switch step {
            case .name: step = .login
            case .mic: step = .name
            default: break
           }
        }
    }
}

#Preview {
    OnboardingFlowView(store: CapyStore())
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

