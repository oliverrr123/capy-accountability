import AuthenticationServices
import AVFoundation
import AudioToolbox
import SwiftUI

struct TaskItem: Identifiable {
    let id = UUID()
    var text: String
    var isDone: Bool
    var timeframe: Timeframe
    
    var coinReward: Int
    var statReward: String?
}

struct StatItem: Identifiable {
    let id = UUID()
    var emoji: String
    var points: Double
}

struct FlyingCoin: Identifiable {
    let id = UUID()
    var startPosition: CGPoint
    let explodeOffset: CGSize
    let endPosition: CGPoint = CGPoint(x: 32, y: 84)
//    var delay: Double
}

enum Timeframe: String, CaseIterable {
    case day = "Today"
    case week = "This week"
    case month = "This month"
    case year = "This year"
    case decade = "This decade"
    case allTime = "All time"
}

struct HomeView2: View {
    @State private var tasks: [TaskItem] = [
        TaskItem(text: "Wake up early", isDone: true, timeframe: .day, coinReward: 10, statReward: "😁"),
        TaskItem(text: "Don't procrastinate", isDone: false, timeframe: .day, coinReward: 10, statReward: nil),
        TaskItem(text: "Do at least 10h on Capy", isDone: false, timeframe: .week, coinReward: 40, statReward: "🍋"),
        TaskItem(text: "Finish MyFriend MVP", isDone: false, timeframe: .month, coinReward: 80, statReward: "😁")
    ]
    
    @State private var showAddAlert = false
    @State private var newTaskText = ""
    
    @State private var stats: [StatItem] = [
        StatItem(emoji: "🍋", points: 1.0),
        StatItem(emoji: "🛁", points: 3.0),
        StatItem(emoji: "😁", points: 2.0)
    ]
    
    @State private var balance = 426.0
    
    @State private var flyingCoins: [FlyingCoin] = []
    
    @State private var audioPlayer: AVAudioPlayer?
    
    @State private var taskToEdit: TaskItem?
    @State private var showActionSheet = false
    @State private var showEditAlert = false
    @State private var editTaskText = ""
    
    @State private var selectedTimeframe: Timeframe = .day
    
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
                    Spacer()
                    
                    topBar
                    
                    Spacer()
                    
                    todoPart
                    
                    Spacer()
                    
                    capyPart
                }
            }
            
            GeometryReader { _ in
                ForEach(flyingCoins) { coin in
                    Image("coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
//                        .position(coin.startPosition)
                        .modifier(ExplodingCoinModifier(coin: coin) {
                            flyingCoins.removeAll(where: { $0.id == coin.id })
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                balance += 1
                            }
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        })
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
//        .coordinateSpace(name: "CapySpace")
        .alert("New Goal", isPresented: $showAddAlert) {
            TextField("Enter goal...", text: $newTaskText)
            Button("Add", action: addNewTask)
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Edit task", isPresented: $showActionSheet) {
            Button("Edit text") {
                if let task = taskToEdit {
                    editTaskText = task.text
                    showEditAlert = true
                }
            }
            
            Button("Delete", role: .destructive) {
                if let task = taskToEdit {
                    deleteTask(task)
                }
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .alert("Edit Goal", isPresented: $showEditAlert) {
            TextField("Goal text...", text: $editTaskText)
            Button("Save") {
                if let task = taskToEdit, !editTaskText.isEmpty {
                    saveTaskEdit(task, newText: editTaskText)
                }
            }
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
                
                Text(String(Int(balance)))
                    .font(Font.custom("Gaegu-Regular", size: 28))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: balance))
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
            timeframeSwitcher
                .zIndex(1)
            
//            Text("Action steps")
//                .font(.custom("Gaegu-Regular", size: 24))
//                .foregroundStyle(.white)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(.leading, 8)
            
                
            VStack(alignment: .leading) {
                let filteredTasks = tasks.filter { $0.timeframe == selectedTimeframe }
                
                if filteredTasks.isEmpty {
                    VStack {
                        Spacer()
                        Text("No goals for \(selectedTimeframe.rawValue.lowercased()) yet!")
                            .font(.custom("Gaegu-Regular", size: 20))
                            .foregroundStyle(Color.capyDarkBrown.opacity(0.5))
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(filteredTasks) { task in
                                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                                    HStack {
                                        Image(tasks[index].isDone ? "tick_done" : "tick_empty")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24)
                                        
                                        Text(tasks[index].text)
                                            .font(.custom("Gaegu-Regular", size: 24))
                                            .strikethrough(task.isDone)
                                            .foregroundStyle(Color.capyDarkBrown)
                                            .multilineTextAlignment(.leading)
//                                            .layoutPriority(1)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .onTapGesture(coordinateSpace: .global) { location in
                                        toggleTask($tasks[index], at: location)
                                    }
            //                    .gesture(
            //                        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            //                            .onEnded { value in
            //                                toggleTask($task, at: value.startLocation)
            //                            }
            //                    )
                                    .onLongPressGesture {
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                        
                                        taskToEdit = task
                                        showActionSheet = true
                                    }
                                }
                            }
                        }
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
            .frame(height: UIScreen.main.bounds.height * 0.28)
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
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width < -50 {
                            changeTimeframe(direction: 1)
                        } else if value.translation.width > 50 {
                            changeTimeframe(direction: -1)
                        }
                    }
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var timeframeSwitcher: some View {
        HStack {
            Button(action: { changeTimeframe(direction: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            
            Spacer()
            
            Text(selectedTimeframe.rawValue)
                .font(.custom("Gaegu-Regular", size: 24))
                .foregroundStyle(.white)
            
            Spacer()
            
            Button(action: { changeTimeframe(direction: 1) }) {
                Image(systemName: "chevron.right")
                    .font(Font.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 40)
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
                                    .foregroundStyle(Int(stat.points) <= 1 ? Color.red : Color.capyDarkBrown)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.8))
                    .clipShape(Capsule())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
        }
        .ignoresSafeArea()
    }
    
    private func changeTimeframe(direction: Int) {
        let allCases = Timeframe.allCases
        if let currentIndex = allCases.firstIndex(of: selectedTimeframe) {
            let nextIndex = (currentIndex + direction + allCases.count) % allCases.count
            withAnimation {
                selectedTimeframe = allCases[nextIndex]
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    private func toggleTask(_ task: Binding<TaskItem>, at location: CGPoint) {
        withAnimation(.spring()) {
            task.wrappedValue.isDone.toggle()
        }
        
        let reward = task.wrappedValue.coinReward
        let statEmoji = task.wrappedValue.statReward
        
        if task.wrappedValue.isDone {
            triggerReward(at: location, amount: reward)
            if let emoji = statEmoji { updateStat(emoji: emoji, change: 1) }
        } else {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            withAnimation {
                balance -= Double(reward)
                if let emoji = statEmoji { updateStat(emoji: emoji, change: -1) }
            }
        }
    }
    
    private func updateStat(emoji: String, change: Double) {
        if let index = stats.firstIndex(where: { $0.emoji == emoji }) {
            withAnimation {
                let newPoints = stats[index].points + change
                stats[index].points = min(max(newPoints, 0), 5)
            }
        }
    }
    
    private func triggerReward(at point: CGPoint, amount: Int) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
//        AudioServicesPlaySystemSound(1407)
        playSound(name: "coins", fileExtension: "mp3")
        
        spawnCoins(from: point, count: amount)
    }
    
    private func playSound(name: String, fileExtension: String) {
        if let url = Bundle.main.url(forResource: name, withExtension: fileExtension) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        } else {
            print("Could not find file: \(name).\(fileExtension)")
        }
    }
    
    private func spawnCoins(from startPoint: CGPoint, count: Int) {
        let visualCoins = min(count, 100)
        for _ in 0..<visualCoins {
            let randomX = Double.random(in: -10...10)
            let randomY = Double.random(in: -10...10)
            let offset = CGSize(width: randomX, height: randomY)
            
            let coin = FlyingCoin(
                startPosition: startPoint,
                explodeOffset: offset
//                delay: Double(i) * 0.05
            )
            flyingCoins.append(coin)
        }
    }
    
    private func addNewTask() {
        guard !newTaskText.isEmpty else { return }
        
        let newItem = TaskItem(
            text: newTaskText,
            isDone: false,
            timeframe: selectedTimeframe,
            coinReward: 12,
            statReward: nil
        )
        
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
    
    private func saveTaskEdit(_ item: TaskItem, newText: String) {
        if let index = tasks.firstIndex(where: { $0.id == item.id }) {
            tasks[index].text = newText
        }
    }
}

struct ExplodingCoinModifier: ViewModifier {
    let coin: FlyingCoin
    var onComplete: () -> Void
    
    @State private var isVisible = false
    @State private var isExploded = false
    @State private var isMagnetized = false
    
    func body(content: Content) -> some View {
        content
            .position(
                isMagnetized ? coin.endPosition :
                    (isExploded ? CGPoint(x: coin.startPosition.x + coin.explodeOffset.width,
                                          y: coin.startPosition.y + coin.explodeOffset.height) :
                    coin.startPosition)
            )
            .opacity(isVisible ? 1 : 0)
//            .scaleEffect(isVisible ? 1 : 0.1)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    isVisible = true
                    isExploded = true
                }
                
                let magnetDelay = Double.random(in: 0.05...0.4)
                let magnetDuration = 0.6
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + magnetDelay) {
                    withAnimation(.easeIn(duration: 0.6)) {
                        isMagnetized = true
                    }
                }
                
                let totalDuration = 0.3 + magnetDelay + magnetDuration
                
                DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
                    onComplete()
                }
            }
    }
}

#Preview {
    InitialView()
}
