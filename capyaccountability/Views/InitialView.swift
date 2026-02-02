import SwiftUI

struct InitialView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Text("Capy").font(.custom("CherryBombOne-Regular", size: 96)).foregroundStyle(.white)
            Text("Accountability").font(.custom("CherryBombOne-Regular", size: 32)).foregroundStyle(.white)
            
            Spacer()
            
            Image("Capy")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .saturation(/*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 28/255, green: 149/255, blue: 255/255))
        .ignoresSafeArea()
        
//        ZStack {
//            Color.capyBlue
//                .ignoresSafeArea()
//            
//            VStack(spacing: 0) {
//                Spacer()
//                    .frame(height: 60)
//                
//                // Logo Section
//                VStack(spacing: 8) {
//                    Text("Capy")
//                        .font(.system(size: 80, weight: .black, design: .rounded))
//                        .foregroundStyle(.white)
//                    
//                    Text("Accountability")
//                        .font(.system(size: 28, weight: .bold, design: .rounded))
//                        .foregroundStyle(.white)
//                }
//                
//                Spacer()
//                
//                // Image Placeholder
//                // In a real app, this would be an Image("capybara_hero")
//                Image(systemName: "pawprint.fill") // Placeholder
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 200, height: 200)
//                    .foregroundStyle(.white.opacity(0.5))
//                    .padding()
//                
//                Spacer()
//                
//                // Bottom Sheet
//                VStack(spacing: 20) {
//                    Text("lets get this done")
//                        .font(.system(size: 24, weight: .medium, design: .rounded))
//                        .foregroundStyle(.black)
//                        .padding(.top, 20)
//                    
//                    Button(action: {
//                        // TODO: Login Action
//                    }) {
//                        Text("Log In")
//                            .font(.system(size: 20, weight: .semibold, design: .rounded))
//                            .foregroundStyle(.black)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.capyBeige)
//                            .cornerRadius(30)
//                    }
//                    
//                    Button(action: {
//                        // TODO: Create Account Action
//                    }) {
//                        Text("Create an Account")
//                            .font(.system(size: 20, weight: .semibold, design: .rounded))
//                            .foregroundStyle(.white)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.capyBrown)
//                            .cornerRadius(30)
//                    }
//                }
//                .padding(30)
//                .background(.ultraThinMaterial)
//                .cornerRadius(30)
//                .padding(.horizontal, 20)
//                .padding(.bottom, 40)
//            }
//        }
    }
}

#Preview {
    InitialView()
}
