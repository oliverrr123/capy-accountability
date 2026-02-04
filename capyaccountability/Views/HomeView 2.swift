import AuthenticationServices
import AVFoundation
import SwiftUI

struct TaskItem: Identifiable {
    let id = UUID()
    var text: String
    var isDone: Bool
}

struct StatItem: Identifiable {
    let id = UUID()
    var emoji: String
    var points: Double
}

struct HomeView2: View {
    @State private var tasks: [TaskItem] = [
        TaskItem(text: "Wake up early", isDone: true),
        TaskItem(text: "Do at least 10h on Capy", isDone: false),
        TaskItem(text: "Finish MyFriend MVP", isDone: false)
    ]
    
    @State private var showAddAlert = false
    @State private var newTaskText = ""
    
    @State private var stats: [StatItem] = [
        StatItem(emoji: "🍋", points: 1.0),
        StatItem(emoji: "🛁", points: 3.0),
        StatItem(emoji: "😁", points: 5.0)
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
                    
                    topBar
                    
                    Spacer()
                    
                    todoPart
                    
                    Spacer()
                    
                    capyPart
                }
            }
        }
        .alert("New Goal", isPresented: $showAddAlert) {
            TextField("Enter goal...", text: $newTaskText)
            Button("Add", action: addNewTask)
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private var topBar: some View {
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
    }
    
    private var todoPart: some View {
        VStack {
            Text("Action steps")
                .font(.custom("Gaegu-Regular", size: 24))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
            
            VStack(alignment: .leading) {
                ForEach($tasks) { $task in
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
                    .onTapGesture {
                        toggleTask($task)
                    }
                    .onLongPressGesture {
                        deleteTask($task.wrappedValue)
                    }
                }
                
                Button(action: {
                    newTaskText = ""
                    showAddAlert = true
                }) {
                    Text("+++++")
                        .font(Font.custom("Gaegu-Regular", size: 24))
                        .foregroundStyle(Color.capyBlue)
                        .padding(.top, 24)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
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
    }
    
    private var capyPart: some View {
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
                .padding(.bottom, 10)
                .overlay(alignment: .bottom) {
                    HStack {
                        ForEach(stats) { stat in
                            HStack {
                                Text(stat.emoji)
                                    .font(Font.system(size: 24, weight: .bold, design: .default))
                                Text("\(Int(stat.points))/5")
                                    .font(.custom("Gaegu-Regular", size: 24))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(.white).opacity(0.8)
                    .clipShape(Capsule())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
        }
        .ignoresSafeArea()
    }
    
    private func toggleTask(_ task: Binding<TaskItem>) {
        withAnimation(.spring()) {
            task.wrappedValue.isDone.toggle()
        }
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func addNewTask() {
        guard !newTaskText.isEmpty else { return }
        
        let newItem = TaskItem(text: newTaskText, isDone: false)
        
        withAnimation {
            tasks.append(newItem)
        }
    }
    
    private func deleteTask(_ item: TaskItem) {
        if let index = tasks.firstIndex(where: {$0.id == item.id }) {
            _ = withAnimation {
                tasks.remove(at: index)
            }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }
}

#Preview {
    InitialView()
}
