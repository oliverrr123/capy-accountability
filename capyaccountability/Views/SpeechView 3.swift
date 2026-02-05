import AuthenticationServices
import AVFoundation
import SwiftUI

struct SpeechView3: View {
    @Binding var name: String
    var onBack: () -> Void
    var onSubmit: () -> Void
    
    @ObservedObject var viewModel: TaskViewModel
    
    @FocusState private var nameFocused: Bool
    
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var brain = CapyBrain()
    
    @State private var showBars = false
    @State private var isThinking = false
    
    @State private var capyText: String = ""
    @State private var messages: [[String: String]] = []
    
    var body: some View {
        ZStack {
            Color.capyBlue
                .ignoresSafeArea()
            
            Image("wallpaper")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.5)
            
            LinearGradient(
                colors: [
                    Color.black.opacity(0.2),
                    Color.black.opacity(0.1),
                    Color.black.opacity(0),
                    Color.black.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                
                Spacer()
                
                VStack(spacing: 32) {
                    VStack {
                        Image("Capy")
                            .resizable()
                            .scaledToFit()
                            .saturation(2)
                            .padding(.horizontal, 60)
                            .padding(.bottom, -40)
                        
                        ZStack {
                            Image("speech_bubble")
                                .resizable()
                                .scaledToFit()
                                .padding(.horizontal, 20)
                                .rotationEffect(Angle(degrees: 180))
                            
                            Text(capyText)
                                .font(.custom("Gaegu-Regular", size: 18))
                                .foregroundStyle(Color.capyDarkBrown)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .padding(.top, 18)
                                .padding(.horizontal, 40)
                        }
                        
                    }
                    
                    VStack {
                        
                        //                        Text("Write instead")
                        //                            .foregroundStyle(.gray, .opacity(0.5))
                        //                            .font(.custom("Gaegu-Regular", size: 28))
                        //                            .padding(.bottom, 18)
                        
                        Button(action: micTapped) {
                            Group {
                                if isThinking {
                                    SpinningLoader()
                                } else if showBars || speechRecognizer.isRecording {
                                    SoundBars(level: CGFloat(speechRecognizer.soundLevel))
                                        .foregroundStyle(Color.capyBlue)
                                        .frame(width: 128, height: 128)
                                } else {
                                    Image("mic_blue")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 128, height: 128)
                                }
                            }
                            .padding(24)
                            
                        }
                        .background(.white)
                        .clipShape(Circle())
                        
                        Text(speechRecognizer.transcript)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.top, 4)

                    }
                }

                
                Spacer()
                
                Spacer()
            }
        }
        .overlay(alignment: .bottomLeading) {
            BackButton(action: onBack)
                .padding(.leading, 18)
                .padding(.bottom, 32)
        }
        .onChange(of: speechRecognizer.isRecording) { oldValue, isRecording in
                if !isRecording {
                    if !speechRecognizer.transcript.isEmpty {
                        askCapy(text: speechRecognizer.transcript)
                    }
            }
        }
        .onAppear {
            capyText = "Hey \(name), what are your goals?"
        }
    }
    
    private func askCapy(text: String) {
        isThinking = true
        
        Task {
            do {
                if messages.isEmpty {
                    messages.append([
                        "role": "assistant",
                        "content": "Hey \(name), what are your goals?"
                    ])
                }
                
                messages.append([
                    "role": "user",
                    "content": text
                ])
                
                let result = try await brain.talkToCapy(messages: messages)
                
                DispatchQueue.main.async {
                    switch result {
                    case .reply(let answer):
                        capyText = answer
                        messages.append(["role": "assistant", "content": capyText])
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            startListening()
                            isThinking = false
                        }
                        
                    case .finished(let goals):
                        print("Goals collected")
                        viewModel.generateTasks(from: goals)
                        isThinking = false
                        onSubmit()
                    }
                }
            } catch {
                print("Error talking to Capy: \(error)")
                isThinking = false
            }
        }
        
        print("Sending to Capy: \(text)")
    }
    
    private func startListening() {
        speechRecognizer.startTranscribing()
        showBars = true
    }
    
    private func submit() {
        nameFocused = false
        onSubmit()
    }
    
    private func micTapped() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopTranscribing()
            showBars = false
            return
        }
        
        let start = {
            speechRecognizer.startTranscribing()
            showBars = true
        }
        
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                start()
            case .undetermined:
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        if granted { start() }
                    }
                }
            case .denied:
                print("Mic denied - enable in Settings")
            @unknown default:
                break
            }
        } else {
            let session = AVAudioSession.sharedInstance()
            switch session.recordPermission {
            case .granted:
                start()
            case .undetermined:
                session.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        if granted { start() }
                    }
                }
            case .denied:
                print("Mic denied - enable in Settings")
            @unknown default:
                break
            }
        }
    }
}

struct SpinningLoader: View {
    var body: some View {
        TimelineView(.animation) { context in
            Image("mic_load")
                .resizable()
                .scaledToFit()
                .frame(width: 128, height: 128)
                .rotationEffect(.degrees(context.date.timeIntervalSinceReferenceDate * 360))
        }
    }
}

#Preview {
    InitialView()
}
