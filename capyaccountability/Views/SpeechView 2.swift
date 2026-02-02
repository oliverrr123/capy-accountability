import AuthenticationServices
import SwiftUI

struct SpeechView2: View {
    @Binding var name: String
    var onSubmit: () -> Void
    
    @FocusState private var nameFocused: Bool
    
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
                
                VStack(spacing: 20) {
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
                        
                        //                    Image("capy_sit")
                        //                        .resizable()
                        //                        .scaledToFit()
                        //                        .padding(.bottom, 10)
                        
                    }
                    
                    HStack {
                        TextField("name", text: $name)
                            .focused($nameFocused)
                            .font(.custom("Gaegu-Regular", size: 28))
                            .foregroundStyle(.black)
                            .submitLabel(.done)
                            .onSubmit { submit() }
                            .padding(.horizontal, 20)
                        
                        Button(action: submit) {
                            Image("arrow_button")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(.horizontal, 20)
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
