import AuthenticationServices
import SwiftUI

struct InitialView: View {
    var body: some View {
        ZStack {
            Image("capy_wallpaper")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            LinearGradient(
                colors: [
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 100)
                
                VStack(spacing: 6) {
                    Text("Capy")
                        .font(.custom("CherryBombOne-Regular", size: 96))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                    
                    Text("Accountability")
                        .font(.custom("CherryBombOne-Regular", size: 32))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                }
                
                Spacer()
                
                Spacer()
                
                VStack(spacing: 14) {
                    
                    SignInWithAppleButton(.signIn, onRequest: { _ in
                        // TODO: Configure request
                    }, onCompletion: { _ in
                        // TODO: Handle completion
                    })
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 67)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.bottom, 52)
            }
        }
    }
}

#Preview {
    InitialView()
}
