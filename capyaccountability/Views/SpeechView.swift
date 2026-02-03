import AuthenticationServices
import SwiftUI

struct SpeechView: View {
    @State private var name = ""
    
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
                
                HStack {
                    TextField("name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.send)
                    
                    Button("Continue") {
                        print("Name: ", name)
                        name = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                
                VStack {
                    ZStack {
                        Image("speech_bubble")
                            .resizable()
                            .scaledToFit()
                            .padding(.horizontal, 20)
                        
                        Text("What's ur name?")
                            .font(.custom("Gaegu-Regular", size: 28))
                            .padding(.bottom, 18)
                    }
                    
                    Image("capy_sit")
                        .resizable()
                        .scaledToFit()
                        .padding(.bottom, 10)
                    
                }
            }
        }
    }
}

#Preview {
    InitialView()
}
