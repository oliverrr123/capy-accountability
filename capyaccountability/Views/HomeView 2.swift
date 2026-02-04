import AuthenticationServices
import AVFoundation
import SwiftUI

struct TaskItem: Identifiable {
    let id = UUID()
    var text: String
    var isDone: Bool
}

struct HomeView2: View {
    @State private var tasks: [TaskItem] = [
        TaskItem(text: "Wake up early", isDone: true),
        TaskItem(text: "Do at least 10h on Capy", isDone: false),
        TaskItem(text: "Finish MyFriend MVP", isDone: false)
    ]
        
    
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
                
                VStack {
                    
                    Spacer()
                    
                    HStack {
                        HStack {
                            Image("coin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            
                            Text("426")
                                .font(Font.custom("Gaegu-Regular", size: 28))
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                        
                        Image("white")
                            .frame(width: 36, height: 36)
                            .background(.white)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    VStack {
                        Text("Action steps")
                            .font(.custom("Gaegu-Regular", size: 24))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        VStack(alignment: .leading) {
                            ForEach(tasks) { task in
                                HStack {
                                    Image(task.isDone ? "tick_done" : "tick_empty")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                    
                                    Text(task.text)
                                        .font(.custom("Gaegu-Regular", size: 24))
                                        .strikethrough(task.isDone)
                                        .foregroundStyle(Color.capyDarkBrown)
                                }
                            }
                            
                            Text("+++++")
                                .font(Font.custom("Gaegu-Regular", size: 24))
                                .foregroundStyle(Color.capyBlue)
                                .padding(.top, 24)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                        }
                        .padding(16)
                        .background {
                            ZStack {
                                Color.white
                                Image("clouds")
                                    .resizable()
                                    .scaledToFill()
                                    .clipped()
                                    .opacity(0.4)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    VStack(spacing: -16) {
                        ZStack {
                            Image("speech_bubble")
                                .resizable()
                                .scaledToFit()
                            
                            Text("How many hours so far? I'm hungry...")
                                .font(.custom("Gaegu-Regular", size: 24))
                                .foregroundStyle(Color.capyDarkBrown)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 56)
                        }
                        .padding(.horizontal, 20)
                        
                        Image("capy_sit")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 0)
                    }
                    .ignoresSafeArea()
                }
            }
        }
//        .overlay(alignment: .bottomLeading) {
//            BackButton(action: onBack)
//                .padding(.leading, 18)
//                .padding(.bottom, 32)
//        }
//        .onAppear {
//            capyText = "Hey \(name), what are your goals?"
//        }
    }
}

#Preview {
    InitialView()
}
