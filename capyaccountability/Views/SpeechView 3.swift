import AuthenticationServices
import SwiftUI

struct SpeechView3: View {
    @Binding var name: String
    var onSubmit: () -> Void
    
    @FocusState private var nameFocused: Bool
    
    @StateObject private var mic = MicLevelMeter()
    
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
                            
                            Text("What's ur name?")
                                .font(.custom("Gaegu-Regular", size: 28))
                                .padding(.bottom, 18)
                        }
                        
                    }
                    
                    VStack {
                        //                        Button(action: submit) {
                        //                            Image("mic_blue")
                        //                                .resizable()
                        //                                .scaledToFit()
                        //                                .frame(width: 96, height: 96)
                        //                                .padding(24)
                        //                        }
                        //                        .background(.white)
                        //                        .clipShape(Circle())
                        
                        //                        Text("Write instead")
                        //                            .foregroundStyle(.gray, .opacity(0.5))
                        //                            .font(.custom("Gaegu-Regular", size: 28))
                        //                            .padding(.bottom, 18)
                        
                        Button {
                            if mic.isRunning { mic.stop() } else { mic.start() }
                        } label: {
                            SoundBars(level: mic.level)
                                .foregroundStyle(Color.capyBlue)
                                .frame(width: 128, height: 128)
                                .padding(24)
                        }
                        .background(.white)
                        .clipShape(Circle())

                    }
                }

                
                Spacer()
                
                Spacer()
            }
        }
    }
    
    private func submit() {
        nameFocused = false
        onSubmit()
    }
}

#Preview {
    InitialView()
}
