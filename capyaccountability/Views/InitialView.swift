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
                    Color.black.opacity(0.2),
                    Color.black.opacity(0.1),
                    Color.black.opacity(0),
                    Color.black.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 100)
                
                VStack(spacing: 0) {
                    Text("Capy")
                        .font(.custom("CherryBombOne-Regular", size: 128))
                        .foregroundStyle(.white)
                        .shadow(color: .skyBlue.opacity(1), radius: 20, x: 0, y: 4)
                    
                    Text("Accountability")
                        .font(.custom("CherryBombOne-Regular", size: 32))
                        .foregroundStyle(.white)
                        .shadow(color: .skyBlue.opacity(1), radius: 5, x: 2, y: 1)
                        .padding(.top, -18)
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
//                .background(.ultraThinMaterial)
//                .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.bottom, 52)
            }
        }
    }
}

#Preview {
    InitialView()
}
