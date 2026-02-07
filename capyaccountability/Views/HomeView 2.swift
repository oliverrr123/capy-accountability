import AuthenticationServices
import AVFoundation
import AudioToolbox
import Combine
import SwiftUI
import Speech

struct StatItem: Identifiable {
    let id = UUID()
    var emoji: String
    var points: Double
}

struct FlyingCoin: Identifiable {
    let id = UUID()
    var startPosition: CGPoint
    let explodeOffset: CGSize
    let endPosition: CGPoint
    let value: Int
}

struct CapyShopItem: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let description: String
    let cost: Int
    let statReward: String?
}

extension CapyShopItem {
    static let catalog: [CapyShopItem] = [
        CapyShopItem(id: "citrus_treats", emoji: "🍋", title: "Citrus Treats", description: "A snack pack for your capy. Boosts energy.", cost: 28, statReward: "🍋"),
        CapyShopItem(id: "bubble_bath", emoji: "🛁", title: "Bubble Bath", description: "A warm cleanup for your capy after a long day.", cost: 34, statReward: "🛁"),
        CapyShopItem(id: "soft_blanket", emoji: "🧺", title: "Soft Blanket", description: "Comfy rest setup that keeps your capy relaxed.", cost: 30, statReward: "😁"),
        CapyShopItem(id: "watermelon_bowl", emoji: "🍉", title: "Watermelon Bowl", description: "Fresh fruit serving for your capy’s mood.", cost: 32, statReward: "😁"),
        CapyShopItem(id: "river_toy", emoji: "🦆", title: "River Toy", description: "A playful floatie toy for capy fun time.", cost: 26, statReward: "😁"),
        CapyShopItem(id: "leaf_salad", emoji: "🥬", title: "Leaf Salad", description: "Healthy greens to keep your capy nourished.", cost: 22, statReward: "🍋"),
        CapyShopItem(id: "sun_hat", emoji: "👒", title: "Sun Hat", description: "Cute outdoor hat so your capy stays comfy outside.", cost: 36, statReward: nil),
        CapyShopItem(id: "rain_boots", emoji: "🥾", title: "Rain Boots", description: "For splashy walks with your capy.", cost: 24, statReward: nil),
        CapyShopItem(id: "reed_mat", emoji: "🧶", title: "Reed Mat", description: "A calm corner mat for your capy to chill.", cost: 31, statReward: "🛁"),
        CapyShopItem(id: "pond_pass", emoji: "🎟️", title: "Pond Pass", description: "A little day pass for capy water play.", cost: 42, statReward: "😁"),
        CapyShopItem(id: "grooming_kit", emoji: "🪮", title: "Grooming Kit", description: "Brush and care tools for your capy.", cost: 40, statReward: "🛁"),
        CapyShopItem(id: "cozy_lantern", emoji: "🏮", title: "Cozy Lantern", description: "Night-time ambience for your capy’s space.", cost: 38, statReward: nil)
    ]
}

enum ThinkingState {
    case none
    case text
    case mic
}

extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { $0.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect }
            .map { $0.height }
        
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

//struct SoundBarsSmalll: View {
//    var level: CGFloat
//    
//    var body: some View {
//        HStack(spacing: 4) {
//            bar(delay: 0.0)
//            bar(delay: 0.1)
//            bar(delay: 0.2)
//        }
//    }
//    
//    func bar(delay: Double) -> some View {
//        let height = max(10, CGFloat(level) * 40 + CGFloat.random(in: 0...10))
//        
//        return RoundedRectangle(cornerRadius: 2)
//            .fill(Color.white)
//            .frame(width: 4, height: height)
//            .animation(.easeInOut(duration: 0.15), value: level)
//    }
//}

struct SoundBarsSmall: View {
    var level: CGFloat
    
    private let weights: [CGFloat] = [0.15, 1.0, 0.8, 0.5]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(weights.indices, id: \.self) { i in
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white)
                    .frame(width: 4, height: barHeight(weights[i]))
            }
        }
        .animation(.easeIn(duration: 0.02), value: level)
    }
    
    private func barHeight(_ weight: CGFloat) -> CGFloat {
        let cleanLevel = level < 0.01 ? 0 : level
        let boostedLevel = sqrt(cleanLevel)
        let minHeight: CGFloat = 8
        let maxHeight: CGFloat = 36
        let jitter = CGFloat.random(in: 0.9...1.1)
        return minHeight + (boostedLevel * maxHeight * weight * jitter)
    }
}

struct CircularTranscriptRing: View {
    var transcript: String
    var ringDiameter: CGFloat = 72

    private let visibleCharacterCount = 42
    private let fallbackText = " LISTENING • "

    private var ringCharacters: [Character] {
        let cleaned = transcript
            .uppercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let source = cleaned.isEmpty ? fallbackText : " \(cleaned) • "
        if source.count >= visibleCharacterCount {
            return Array(source.suffix(visibleCharacterCount))
        }

        let repeats = max((visibleCharacterCount + source.count - 1) / source.count, 1)
        let repeated = String(repeating: source, count: repeats)
        return Array(repeated.prefix(visibleCharacterCount))
    }

    var body: some View {
        let chars = ringCharacters
        let step = 360.0 / Double(chars.count)

        ZStack {
            ForEach(Array(chars.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(.custom("Gaegu-Bold", size: 9))
                    .foregroundStyle(.white.opacity(0.95))
                    .offset(y: -(ringDiameter / 2))
                    .rotationEffect(.degrees(Double(index) * step))
            }
        }
        .frame(width: ringDiameter + 18, height: ringDiameter + 18)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct HomeView2: View {
    @ObservedObject var store: CapyStore

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var brain = CapyBrain()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var liveActivityManager = CapyLiveActivityManager()

    @AppStorage("capy_shop_last_day_key") private var shopLastDayKey = ""
    @AppStorage("capy_shop_purchased_ids") private var purchasedShopItemsCSV = ""
    @AppStorage("capy_last_goal_checkin_ts") private var lastGoalCheckInTimestamp = 0.0
    @AppStorage("capy_last_wake_day_key") private var lastWakeDayKey = ""
    @AppStorage("capy_live_activity_enabled") private var liveActivityEnabled = false
    @AppStorage("capy_live_activity_mode") private var liveActivityModeRaw = CapyLiveActivityMode.capyCare.rawValue
    @AppStorage("capy_live_activity_goal_scope") private var liveActivityGoalScopeRaw = CapyLiveActivityGoalScope.allGoals.rawValue

    @State private var showAddAlert = false
    @State private var newTaskText = ""

    @State private var stats: [StatItem] = [
        StatItem(emoji: "🍋", points: 1.0),
        StatItem(emoji: "🛁", points: 3.0),
        StatItem(emoji: "😁", points: 2.0)
    ]
    
    @State private var balanceDisplay: Double = 0.0
    @State private var flyingCoins: [FlyingCoin] = []
    @State private var audioPlayer: AVAudioPlayer?
    
    @State private var isCollectingCoins = false

    @State private var taskToEdit: CapyTask?
    @State private var showActionSheet = false
    @State private var showEditAlert = false
    @State private var editTaskText = ""
    @State private var selectedFrequency: TaskFrequency = .daily

    @State private var showShopSheet = false
    @State private var showLiveActivitySheet = false
    @State private var shopItems: [CapyShopItem] = []
    @State private var currentShopDayKey = ""
    @State private var showShopAlert = false
    @State private var shopAlertMessage = ""

    @State private var capyText = "yo bro, i'm capy. tap capyshop if you wanna grab me care stuff."
    
    @State private var showChatInput = false
    @State private var chatInputText = ""
    @FocusState private var isChatFocused: Bool
    @State private var thinkingState: ThinkingState = .none
    @State private var keyboardHeight: CGFloat = 0
    @State private var coinIconTarget: CGPoint = .zero
    
    @State private var isCapySleeping = false
    @State private var lastSessionGoalCheckInDate = Date.distantPast
    @State private var topSafePadding: CGFloat = 59

    private let goalCheckInTimer = Timer.publish(every: 10 * 60, on: .main, in: .common).autoconnect()
    private let capySleepTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var liveActivityModeSelection: Binding<CapyLiveActivityMode> {
        Binding(
            get: { liveActivityMode },
            set: { liveActivityModeRaw = $0.rawValue }
        )
    }

    private var liveActivityGoalScopeSelection: Binding<CapyLiveActivityGoalScope> {
        Binding(
            get: { liveActivityGoalScope },
            set: { liveActivityGoalScopeRaw = $0.rawValue }
        )
    }

    private var homeContent: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                backGroundLayer
                gameContentLayer(geometry: geometry)
                    .frame(height: UIScreen.main.bounds.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .opacity(showChatInput ? 0.3 : 1.0)
                    .animation(.spring, value: showChatInput)
                
                capyPart
                    .frame(width: UIScreen.main.bounds.width)
                    .offset(y: keyboardHeight > 0 ? -(keyboardHeight-20) : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: keyboardHeight)
                    .zIndex(10)
                    .onTapGesture {
                        if showChatInput {
                            closeChat()
                        } else {
                            handleCapyTap()
                        }
                    }
                    .ignoresSafeArea()
                
                chatInterfaceLayer
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .zIndex(20)
            }
            .coordinateSpace(name: "homeLayer")
            .overlay(coinsLayer)
            .onAppear {
                topSafePadding = geometry.safeAreaInsets.top
            }
            .onChange(of: geometry.safeAreaInsets.top) { _, newValue in
                topSafePadding = newValue
            }
        }
    }

    private var shopSheetContent: some View {
        CapyShopSheet(
            dayLabel: shopDayLabel(from: currentShopDayKey),
            balance: store.stats.coins,
            items: shopItems,
            isPurchased: { isPurchased($0) },
            onBuy: { buyShopItem($0) }
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private var liveActivitySheetContent: some View {
        LiveActivitySetupSheet(
            isEnabled: $liveActivityEnabled,
            mode: liveActivityModeSelection,
            goalScope: liveActivityGoalScopeSelection,
            pendingDailyCount: pendingDailyTasks.count,
            pendingOtherCount: pendingNonDailyTasks.count
        ) {
            syncLiveActivity()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    var body: some View {
        homeContent
        .onReceive(Publishers.keyboardHeight) { self.keyboardHeight = $0 }
        .ignoresSafeArea()
        .onChange(of: speechRecognizer.isRecording) { _, isRecording in
            guard !isRecording else { return }
            let finalTranscript = speechRecognizer.transcript
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !finalTranscript.isEmpty else { return }
            sendVoiceMessage(finalTranscript)
            speechRecognizer.transcript = ""
        }
        .alert("New Goal", isPresented: $showAddAlert) {
            TextField("Enter goal...", text: $newTaskText)
            Button("Add", action: addNewTask)
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Edit task", isPresented: $showActionSheet) {
            Button("Edit text") {
                if let task = taskToEdit {
                    editTaskText = task.title
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
                    store.deleteTask(task)
                    store.addTask(title: editTaskText, frequency: selectedFrequency)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
//        .alert("Chat with Capy", isPresented: $showChatAlert) {
//            TextField("Say something...", text: $chatInputText)
//            Button("Send") { sendMessageToCapy() }
//            Button("Cancel", role: .cancel) {}
//        }
        .alert("CapyShop", isPresented: $showShopAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(shopAlertMessage)
        }
        .sheet(isPresented: $showShopSheet) {
            shopSheetContent
        }
        .sheet(isPresented: $showLiveActivitySheet) {
            liveActivitySheetContent
        }
        .onAppear {
            balanceDisplay = Double(store.stats.coins)
            refreshDailyShopIfNeeded(force: true)
            refreshCapySleepState()
            syncLiveActivity()
        }
        .onChange(of: store.stats.coins) { _, newValue in
            if !isCollectingCoins {
                withAnimation {
                    balanceDisplay = Double(newValue)
                }
            }
            syncLiveActivity()
        }
        .onChange(of: store.tasks) { _, _ in
            syncLiveActivity()
        }
        .onChange(of: liveActivityEnabled) { _, _ in
            syncLiveActivity()
        }
        .onChange(of: liveActivityModeRaw) { _, _ in
            syncLiveActivity()
        }
        .onChange(of: liveActivityGoalScopeRaw) { _, _ in
            syncLiveActivity()
        }
        .onChange(of: isCapySleeping) { _, _ in
            syncLiveActivity()
        }
        .onReceive(goalCheckInTimer) { _ in
            maybeAskGoalCheckIn()
        }
        .onReceive(capySleepTimer) { _ in
            refreshCapySleepState()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshDailyShopIfNeeded()
                refreshCapySleepState()
            }
            syncLiveActivity(isAwayOverride: newPhase != .active)
        }
    }
    
    private func gameContentLayer(geometry: GeometryProxy) -> some View {
        VStack(spacing: 10) {
//            Spacer()
            topBar
//                    shopCareHint
            todoPart
            Spacer()
//            capyPart
            Spacer().frame(height: 120)
        }
        .padding(.top, geometry.safeAreaInsets.top + 70)
        .frame(width: geometry.size.width)
    }
    
    private var chatInterfaceLayer: some View {
        VStack {
            Spacer()
            if showChatInput {
                chatInputBar
            } else {
                statsAndChatButton
            }
        }
        .padding(.bottom, keyboardHeight > 0 ? keyboardHeight : (showChatInput ? 0 : 30))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: keyboardHeight)
    }
    
    private var chatInputBar: some View {
        HStack(spacing: 8) {
            Button {
                closeChat()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.gray.opacity(0.2))
            }
            
            TextField("talk to capy...", text: $chatInputText)
                .font(.custom("Gaegu-Regular", size: 20))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.2))
                .clipShape(Capsule())
                .focused($isChatFocused)
                .submitLabel(.send)
                .onSubmit { sendMessageToCapy() }
            
            Button {
                sendMessageToCapy()
            } label: {
                Image("send")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .frame(width: 44, height: 44)
                    .background(chatInputText.isEmpty ? Color.gray.opacity(0.2) : Color.capyBlue)
                    .clipShape(Circle())
            }
            .disabled(chatInputText.isEmpty)
        }
        .padding(12)
        .background(Color.white)
//        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 5, y: -2)
//        .padding(.horizontal, 10)
//        .padding(.bottom, 5)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var statsAndChatButton: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(spacing: 12) {
                ForEach(stats) { stat in
                    VStack(spacing: 0) {
                        Text(stat.emoji)
                            .font(.system(size: 22))
                        Text("\(Int(stat.points))/5")
                            .font(.custom("Gaegu-Regular", size: 14))
                            .foregroundStyle(Int(stat.points) <= 1 ? Color.red : Color.capyDarkBrown)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(.white.opacity(0.9))
            .clipShape(Capsule())
            
            Spacer()
            
            Button(action: handleMicTap) {
                ZStack {
                    Circle()
                        .fill(Color.capyBlue)
                        .frame(width: 50, height: 50)
                        .shadow(radius: 4)
                    
                    if speechRecognizer.isRecording {
//                        Image(systemName: "waveform")
//                            .font(.system(size: 24))
//                            .foregroundStyle(.white)
                        SoundBarsSmall(level: CGFloat(speechRecognizer.soundLevel))
                    } else if thinkingState == .mic {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                }
                .overlay {
                    if speechRecognizer.isRecording {
                        CircularTranscriptRing(transcript: speechRecognizer.transcript)
                    }
                }
            }
            .disabled(isCapySleeping || thinkingState != .none)
            .opacity(isCapySleeping ? 0.6 : 1.0)
            .accessibilityLabel(speechRecognizer.isRecording ? "Stop Dictate" : "Dictate")
            
            Button(action: openChat) {
                ZStack {
                    Circle()
                        .fill(Color.capyBlue)
                        .frame(width: 50, height: 50)
                        .shadow(radius: 4)
                    if thinkingState == .text {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "bubble.right.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }
                }
            }
            .disabled(isCapySleeping || thinkingState != .none)
            .opacity(isCapySleeping ? 0.6 : 1.0)
        }
        .padding(.horizontal, 20)
//        .padding(.bottom, 30)
//        .transition(.opacity)
    }
    
    private var backGroundLayer: some View {
        ZStack {
            Color.capyBlue
            Image("wallpaper")
                .resizable()
                .scaledToFill()
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
        }
        .ignoresSafeArea()
//            .onTapGesture {
//                if showChatInput { closeChat() }
//            }
    }
    
    private var coinsLayer: some View {
        ForEach(flyingCoins) { coin in
            Image("coin")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .modifier(ExplodingCoinModifier(coin: coin) {
                    flyingCoins.removeAll(where: { $0.id == coin.id })
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        balanceDisplay += Double(coin.value)
                    }
                    
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                })
        }
    }

    private var topBar: some View {
        HStack {
            HStack {
                Image("coin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    let frame = geo.frame(in: .named("homeLayer"))
                                    coinIconTarget = CGPoint(x: frame.midX, y: frame.midY)
                                }
                                .onChange(of: geo.frame(in: .named("homeLayer"))) { _, newFrame in
                                    coinIconTarget = CGPoint(x: newFrame.midX, y: newFrame.midY)
                                }
                        }
                    )

                Text(String(Int(balanceDisplay)))
                    .font(Font.custom("Gaegu-Regular", size: 28))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: balanceDisplay))
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    showLiveActivitySheet = true
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(liveActivityEnabled ? Color.green : Color.gray.opacity(0.5))
                            .frame(width: 8, height: 8)
                        Text(liveActivityEnabled ? liveActivityMode.shortLabel : "live")
                            .font(.custom("Gaegu-Regular", size: 20))
                    }
                    .foregroundStyle(Color.capyDarkBrown)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.92))
                    .clipShape(Capsule())
                }

                Button {
                    refreshDailyShopIfNeeded()
                    showShopSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "storefront.fill")
                        Text("capyshop")
                            .font(.custom("Gaegu-Regular", size: 20))
                    }
                    .foregroundStyle(Color.capyDarkBrown)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.92))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 20)
    }

//    private var shopCareHint: some View {
//        HStack(spacing: 8) {
//            Image(systemName: "heart.fill")
//                .font(.system(size: 12, weight: .semibold))
//            Text("tap capyshop (top right), buy with coins, each item shows its effect")
//                .font(.custom("Gaegu-Regular", size: 16))
//        }
//        .foregroundStyle(Color.capyDarkBrown.opacity(0.9))
//        .padding(.horizontal, 14)
//        .padding(.vertical, 8)
//        .background(.white.opacity(0.88))
//        .clipShape(Capsule())
//        .padding(.horizontal, 20)
//    }

    private var todoPart: some View {
        VStack(spacing: 6) {
            timeframeSwitcher
                .zIndex(1)

            VStack(alignment: .leading) {
                let filteredTasks = store.tasks.filter { $0.frequency == selectedFrequency }

                if filteredTasks.isEmpty {
                    VStack {
                        Spacer()
                        Text("No goals for \(frequencyLabel(selectedFrequency)) yet!")
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
                                    HStack {
                                        Image(task.isDone ? "tick_done" : "tick_empty")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24)

                                        Text(task.title)
                                            .font(.custom("Gaegu-Regular", size: 24))
                                            .strikethrough(task.isDone)
                                            .foregroundStyle(Color.capyDarkBrown)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .onTapGesture(coordinateSpace: .global) { location in
                                        toggleTask(task, at: location)
                                    }
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
                            changeFrequency(1)
                        } else if value.translation.width > 50 {
                            changeFrequency(-1)
                        }
                    }
            )
        }
        .padding(.horizontal, 20)
    }

    private var timeframeSwitcher: some View {
        HStack {
            Button(action: { changeFrequency(-1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }

            Spacer()

            Text(selectedFrequency.rawValue)
                .font(.custom("Gaegu-Regular", size: 24))
                .foregroundStyle(.white)

            Spacer()

            Button(action: { changeFrequency(1) }) {
                Image(systemName: "chevron.right")
                    .font(Font.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 40)
    }

    private var capyPart: some View {
        VStack(spacing: -6) {
            Spacer()
            ZStack {
                Image("speech_bubble")
                    .resizable()
                    .scaledToFit()

                VStack(alignment: .leading, spacing: 8) {
                    Text(capyText)
                        .font(.custom("Gaegu-Regular", size: 21))
                        .foregroundStyle(Color.capyDarkBrown)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .lineLimit(4)
                        .minimumScaleFactor(0.8)

//                    if thinkingState != .none {
//                        HStack(spacing: 8) {
//                            ProgressView()
//                                .tint(Color.capyDarkBrown)
//                            Text("capy is thinking...")
//                                .font(.custom("Gaegu-Regular", size: 16))
//                                .foregroundStyle(Color.capyDarkBrown.opacity(0.8))
//                        }
//                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 42)
            }
            .padding(.horizontal, 20)

//            HStack(spacing: 10) {
//                TextField("reply to capy...", text: $chatInputText)
//                    .font(.custom("Gaegu-Regular", size: 20))
//                    .foregroundStyle(Color.capyDarkBrown)
//                    .submitLabel(.send)
//                    .onSubmit(sendMessageToCapy)
//                    .disabled(isCapySleeping)
//
//                Button(action: sendMessageToCapy) {
//                    Image(systemName: "paperplane.fill")
//                        .font(.system(size: 16, weight: .semibold))
//                        .foregroundStyle(.white)
//                        .frame(width: 34, height: 34)
//                        .background(Color.capyBlue)
//                        .clipShape(Circle())
//                }
//                .disabled(capyIsThinking || isCapySleeping)
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 10)
//            .background(.white.opacity(0.88))
//            .clipShape(Capsule())
//            .padding(.horizontal, 20)
//            .opacity(isCapySleeping ? 0.7 : 1)

            Image(isCapySleeping ? "capy_sleep" : "capy_sit")
                .resizable()
                .scaledToFill()
                .padding(.bottom, keyboardHeight > 0 ? keyboardHeight/2 : 40)
                .frame(width: UIScreen.main.bounds.width)
//                .padding(.bottom, 10)
                .onTapGesture {
                    handleCapyTap()
                }
                .ignoresSafeArea()
//                .overlay(alignment: .bottom) {
//                    HStack {
//                        ForEach(stats) { stat in
//                            HStack {
//                                Text(stat.emoji)
//                                    .font(Font.system(size: 24, weight: .bold, design: .default))
//                                Text("\(Int(stat.points))/5")
//                                    .font(.custom("Gaegu-Regular", size: 24))
//                                    .foregroundStyle(Int(stat.points) <= 1 ? Color.red : Color.capyDarkBrown)
//                            }
//                            .frame(maxWidth: .infinity)
//                        }
//                    }
//                    .padding(8)
//                    .frame(maxWidth: .infinity)
//                    .background(.white.opacity(0.8))
//                    .clipShape(Capsule())
//                    .padding(.horizontal, 20)
//                    .padding(.bottom, 40)
//                }
        }
//        .frame(maxWidth: .infinity, alignment: .bottom)
//        .ignoresSafeArea()
        .frame(height: 350)
        .frame(width: UIScreen.main.bounds.width)
//        .clipped()
    }

    private var purchasedItemIDs: Set<String> {
        Set(purchasedShopItemsCSV.split(separator: ",").map(String.init))
    }

    private var liveActivityMode: CapyLiveActivityMode {
        get { CapyLiveActivityMode(rawValue: liveActivityModeRaw) ?? .capyCare }
        set { liveActivityModeRaw = newValue.rawValue }
    }

    private var liveActivityGoalScope: CapyLiveActivityGoalScope {
        get { CapyLiveActivityGoalScope(rawValue: liveActivityGoalScopeRaw) ?? .allGoals }
        set { liveActivityGoalScopeRaw = newValue.rawValue }
    }

    private var pendingTasks: [CapyTask] {
        store.tasks.filter { !$0.isDone }
    }

    private var pendingDailyTasks: [CapyTask] {
        pendingTasks.filter { $0.frequency == .daily }
    }

    private var pendingNonDailyTasks: [CapyTask] {
        pendingTasks.filter { $0.frequency != .daily }
    }

    private var liveActivityCandidateTasks: [CapyTask] {
        switch liveActivityGoalScope {
        case .allGoals:
            return pendingDailyTasks + pendingNonDailyTasks
        case .otherGoalsOnly:
            return pendingNonDailyTasks
        }
    }

    private func changeFrequency(_ direction: Int) {
        let allCases = TaskFrequency.allCases
        if let currentIndex = allCases.firstIndex(of: selectedFrequency) {
            let nextIndex = (currentIndex + direction + allCases.count) % allCases.count
            withAnimation {
                selectedFrequency = allCases[nextIndex]
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    private func frequencyLabel(_ f: TaskFrequency) -> String {
        switch f {
        case .daily: return "Daily"
        case .weekly: return "This week"
        case .monthly: return "This month"
        case .yearly: return "This year"
        case .decade: return "This decade"
        case .longTerm: return "Long term"
        }
    }

    private func toggleTask(_ task: CapyTask, at location: CGPoint) {
        let willBeDone = !task.isDone
        
        if willBeDone {
            isCollectingCoins = true
            
            store.toggleTask(task)
            
            let rewardAmount = task.coinReward
            let rewardStat = task.statReward
            
            triggerReward(at: location, amount: rewardAmount)
            if let stat = rewardStat { updateStat(emoji: stat, change: 1) }
            capyText = "nice work bro, you finished \"\(task.title)\"."
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isCollectingCoins = false
                withAnimation {
                    balanceDisplay = Double(store.stats.coins)
                }
            }
        } else {
            store.toggleTask(task)
            
            let rewardStat = task.statReward
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            if let stat = rewardStat { updateStat(emoji: stat, change: -1) }
            capyText = "all good bro, we can take another shot at \"\(task.title)\"."
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
        
        let baseValue = count / visualCoins
        var remainder = count % visualCoins
        
        for _ in 0..<visualCoins {
            let randomX = Double.random(in: -10...10)
            let randomY = Double.random(in: -10...10)
            let offset = CGSize(width: randomX, height: randomY)
            
            let currentValue = baseValue + (remainder > 0 ? 1 : 0)
            if remainder > 0 { remainder -= 1 }

            let coin = FlyingCoin(
                startPosition: startPoint,
                explodeOffset: offset,
                endPosition: coinIconTarget,
                value: currentValue
            )
            flyingCoins.append(coin)
        }
    }

    private func addNewTask() {
        guard !newTaskText.isEmpty else { return }

        withAnimation {
            store.addTask(title: newTaskText, frequency: selectedFrequency)
        }
    }

    private func deleteTask(_ task: CapyTask) {
        withAnimation {
            store.deleteTask(task)
        }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    private func saveTaskEdit(_ task: CapyTask, newText: String) {
        store.deleteTask(task)
        store.addTask(title: newText, frequency: selectedFrequency)
    }

    private func refreshDailyShopIfNeeded(force: Bool = false) {
        let todayKey = shopDayKey(from: Date())
        if !force && todayKey == currentShopDayKey {
            return
        }

        if shopLastDayKey != todayKey {
            shopLastDayKey = todayKey
            purchasedShopItemsCSV = ""
        }

        currentShopDayKey = todayKey
        shopItems = dailyShopItems(for: todayKey)
    }

    private func dailyShopItems(for dayKey: String) -> [CapyShopItem] {
        let ranked = CapyShopItem.catalog.sorted {
            stableHash("\(dayKey)|\($0.id)") < stableHash("\(dayKey)|\($1.id)")
        }
        return Array(ranked.prefix(5))
    }

    private func stableHash(_ value: String) -> UInt64 {
        var hash: UInt64 = 1469598103934665603
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return hash
    }

    private func shopDayKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func shopDayLabel(from dayKey: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"

        let display = DateFormatter()
        display.locale = Locale.current
        display.dateFormat = "EEEE, MMM d"

        guard let date = parser.date(from: dayKey) else {
            return "Today"
        }
        return display.string(from: date)
    }

    private func isPurchased(_ item: CapyShopItem) -> Bool {
        purchasedItemIDs.contains(item.id)
    }

    private func markPurchased(_ itemID: String) {
        var ids = purchasedItemIDs
        ids.insert(itemID)
        purchasedShopItemsCSV = ids.sorted().joined(separator: ",")
    }

    private func buyShopItem(_ item: CapyShopItem) {
        if isPurchased(item) {
            shopAlertMessage = "you already bought \(item.title.lowercased()) today."
            showShopAlert = true
            return
        }
        
        if store.spendCoins(item.cost) {
            markPurchased(item.id)
            if let stat = item.statReward {
                updateStat(emoji: stat, change: 1)
            }
            
            let effectText = itemEffectText(for: item)
            capyText = "thanks bro, you got me \(item.title.lowercased()). \(effectText)"
            shopAlertMessage = "bought \(item.title.lowercased()). \(effectText) capyshop refreshes at midnight."
            showShopAlert = true
        } else {
            shopAlertMessage = "not enough coins for \(item.title.lowercased())."
            showShopAlert = true
        }
    }

    private func maybeAskGoalCheckIn(force: Bool = false) {
        guard !isCapySleeping else { return }
        guard thinkingState == .none else { return }
        guard let targetTask = pendingTasks.randomElement() else { return }

        let now = Date()
        let lastGlobalCheckIn = Date(timeIntervalSince1970: lastGoalCheckInTimestamp)
        let sessionCooldown: TimeInterval = 45 * 60
        let globalCooldown: TimeInterval = 3 * 60 * 60

        if !force {
            guard now.timeIntervalSince(lastSessionGoalCheckInDate) > sessionCooldown else { return }
            guard now.timeIntervalSince(lastGlobalCheckIn) > globalCooldown else { return }
            guard Double.random(in: 0...1) < 0.18 else { return }
        }

        let prompts = [
            "yo bro, how's \"{goal}\" feeling right now?",
            "no pressure bro, got a tiny move for \"{goal}\"?",
            "if you want, we can do a 10-minute step on \"{goal}\".",
            "what would make \"{goal}\" easier tonight, bro?"
        ]

        let template = prompts.randomElement() ?? "how's \"{goal}\" going, bro?"
        capyText = template.replacingOccurrences(of: "{goal}", with: targetTask.title)
        lastSessionGoalCheckInDate = now
        lastGoalCheckInTimestamp = now.timeIntervalSince1970
    }
    
    private func openChat() {
        chatInputText = ""
        withAnimation {
            showChatInput = true
            isChatFocused = true
        }
    }
    
    private func closeChat() {
        withAnimation {
            showChatInput = false
            isChatFocused = false
        }
    }

    private func sendMessageToCapy() {
        let message = chatInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isCapySleeping, !message.isEmpty, thinkingState == .none else { return }

        chatInputText = ""
        closeChat()
        thinkingState = .text
        
        processCoachReply(message: message)
        
//        Task {
//            let reply = await brain.coachReply(
//                userMessage: message,
//                goals: pendingTasks.map { $0.title },
//                completedCount: store.tasks.filter { $0.isDone }.count,
//                pendingCount: pendingTasks.count
//            )
//            await MainActor.run {
//                capyText = reply
//                capyIsThinking = false
//            }
//        }
    }
    
    private func handleMicTap() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopTranscribing()
        } else {
            let start = { speechRecognizer.startTranscribing() }
            
            if #available(iOS 17.0, *) {
                switch AVAudioApplication.shared.recordPermission {
                case .granted: start()
                case .undetermined:
                    AVAudioApplication.requestRecordPermission { granted in
                        DispatchQueue.main.async { if granted { start() } }
                    }
                case .denied: print("Mic denied")
                @unknown default: break
                }
            } else {
                let session = AVAudioSession.sharedInstance()
                switch session.recordPermission {
                case .granted:
                    start()
                case .undetermined:
                    session.requestRecordPermission { granted in
                        DispatchQueue.main.async { if granted { start() } }
                    }
                case .denied: print("Mic denied")
                @unknown default: break
                }
            }
        }
    }
    
    private func sendVoiceMessage(_ text: String) {
        guard !isCapySleeping, thinkingState == .none else { return }
        thinkingState = .mic
        processCoachReply(message: text)
    }
    
    private func processCoachReply(message: String) {
        Task {
            let reply = await brain.coachReply(
                userMessage: message,
                goals: pendingTasks.map { $0.title },
                completedCount: store.tasks.filter { $0.isDone }.count,
                pendingCount: pendingTasks.count
            )
            await MainActor.run {
                capyText = reply
                thinkingState = .none
                if showChatInput {
                    closeChat()
                }
            }
        }
    }

    private func handleCapyTap() {
        if isCapySleeping {
            wakeCapyIfNeeded()
            return
        }
        requestCapyFeelingUpdate()
    }

    private func requestCapyFeelingUpdate() {
        guard thinkingState == .none else { return }
        refreshDailyShopIfNeeded()

        let completed = store.tasks.filter { $0.isDone }.count
        let pending = pendingTasks.count
        let context = capyContextForFeeling()

        thinkingState = .text
        Task {
            let reply = await brain.coachReply(
                userMessage: "i tapped you. tell me how you're feeling with this context. mention time, coins, progress, and one shop item.",
                goals: pendingTasks.map { $0.title },
                completedCount: completed,
                pendingCount: pending,
                extraContext: context
            )
            await MainActor.run {
                capyText = reply
                thinkingState = .none
            }
        }
    }

    private func capyContextForFeeling(now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let timeText = formatter.string(from: now)

        let completedTasks = store.tasks.filter { $0.isDone }
        let remainingTasks = store.tasks.filter { !$0.isDone }
        let topGoals = store.tasks.filter {
            $0.frequency == .longTerm || $0.frequency == .decade || $0.frequency == .yearly
        }

        let endGoalsText = (topGoals.isEmpty ? store.tasks : topGoals)
            .prefix(4)
            .map(\.title)
            .joined(separator: ", ")
        let doneText = completedTasks.prefix(3).map(\.title).joined(separator: ", ")
        let leftText = remainingTasks.prefix(3).map(\.title).joined(separator: ", ")

        let capyStats = stats
            .map { "\(statName(for: $0.emoji)) \(Int($0.points))/5" }
            .joined(separator: ", ")

        let shopSummary = shopItems.prefix(5).map { item in
            let availability = isPurchased(item) ? "bought today" : "available"
            return "\(item.title.lowercased()) (\(item.cost) coins, \(itemEffectText(for: item)), \(availability))"
        }
        .joined(separator: "; ")

        return """
        time: \(timeText).
        capy state: \(isCapySleeping ? "sleepy" : "awake").
        coins: \(Int(balanceDisplay)).
        capy stats: \(capyStats).
        user end goals: \(endGoalsText.isEmpty ? "none yet" : endGoalsText).
        done (\(completedTasks.count)): \(doneText.isEmpty ? "none" : doneText).
        left (\(remainingTasks.count)): \(leftText.isEmpty ? "none" : leftText).
        shop today: \(shopSummary.isEmpty ? "not loaded" : shopSummary).
        """
    }

    private func statName(for emoji: String) -> String {
        switch emoji {
        case "🍋":
            return "energy"
        case "🛁":
            return "hygiene"
        case "😁":
            return "mood"
        default:
            return "stat"
        }
    }

    private func refreshCapySleepState(now: Date = Date()) {
        let todayKey = shopDayKey(from: now)
        let hasReachedMidnight = now >= Calendar.current.startOfDay(for: now)
        let shouldSleep = hasReachedMidnight && lastWakeDayKey != todayKey

        isCapySleeping = shouldSleep

        if shouldSleep {
            capyText = "zzz... tap me to wake me up bro."
        }
    }

    private func wakeCapyIfNeeded() {
        guard isCapySleeping else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            isCapySleeping = false
        }
        lastWakeDayKey = shopDayKey(from: Date())
        capyText = "yawn... i'm up bro. what's one tiny thing we're doing?"

        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    private func itemEffectText(for item: CapyShopItem) -> String {
        guard let stat = item.statReward else {
            return "it is cosmetic only, no stat boost."
        }
        switch stat {
        case "🍋":
            return "+1 energy (🍋)."
        case "🛁":
            return "+1 hygiene (🛁)."
        case "😁":
            return "+1 mood (😁)."
        default:
            return "+1 stat (\(stat))."
        }
    }

    private func syncLiveActivity(isAwayOverride: Bool? = nil) {
        let isAway = isAwayOverride ?? (scenePhase != .active)
        let snapshot = makeLiveActivitySnapshot(isAway: isAway)
        liveActivityManager.sync(enabled: liveActivityEnabled, snapshot: snapshot)
    }

    private func makeLiveActivitySnapshot(isAway: Bool) -> CapyLiveActivitySnapshot {
        let totalTasks = store.tasks.count
        let completedTasks = store.tasks.filter { $0.isDone }.count
        let pendingCount = max(totalTasks - completedTasks, 0)
        let dailyTotal = store.tasks.filter { $0.frequency == .daily }.count
        let dailyCompleted = store.tasks.filter { $0.frequency == .daily && $0.isDone }.count
        let tasksForLiveActivity = liveActivityCandidateTasks
        let nextTask = tasksForLiveActivity.first
        let isDailyPriority = nextTask?.frequency == .daily
        let energyLevel = stats.first(where: { $0.emoji == "🍋" })?.points ?? 3
        let needsFood = energyLevel <= 2 || store.stats.mood == "sleepy"

        let focusText: String
        let progressText: String
        let headline: String

        switch liveActivityMode {
        case .capyCare:
            if needsFood {
                focusText = "Capy needs food soon. Give a quick care boost."
            } else if let title = nextTask?.title {
                focusText = "Capy is good. Next goal: \(title)"
            } else {
                focusText = "Capy is good and your goal list is clear."
            }

            progressText = "daily \(dailyCompleted)/\(dailyTotal) • energy \(Int(energyLevel.rounded()))/5"

            if isAway {
                headline = needsFood ? "away care alert: feed capy" : "away care check: capy is stable"
            } else if isCapySleeping {
                headline = "capy is sleeping"
            } else {
                headline = needsFood ? "capy care priority: food" : "capy care: all good"
            }

        case .accountability:
            if let title = nextTask?.title {
                focusText = isDailyPriority ? "Daily priority: \(title)" : title
            } else if liveActivityGoalScope == .otherGoalsOnly {
                focusText = "No non-daily goals pending."
            } else {
                focusText = "All goals complete."
            }

            progressText = "daily \(dailyCompleted)/\(dailyTotal) • total \(completedTasks)/\(totalTasks)"

            if isAway {
                headline = pendingCount == 0 ? "away accountability: all clear" : "away accountability: \(pendingCount) goals left"
            } else if isCapySleeping {
                headline = "capy is sleeping"
            } else {
                headline = "accountability mode"
            }
        }

        let trimmedName = store.profile.name.trimmingCharacters(in: .whitespacesAndNewlines)

        return CapyLiveActivitySnapshot(
            profileName: trimmedName.isEmpty ? "there" : trimmedName,
            headline: headline,
            focusText: focusText,
            progressText: progressText,
            coins: store.stats.coins,
            isSleeping: isCapySleeping,
            mood: store.stats.mood,
            isAway: isAway,
            mode: liveActivityMode.rawValue,
            goalScope: liveActivityGoalScope.rawValue,
            needsFood: needsFood,
            isDailyPriority: isDailyPriority
        )
    }
}

private struct LiveActivitySetupSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var isEnabled: Bool
    @Binding var mode: CapyLiveActivityMode
    @Binding var goalScope: CapyLiveActivityGoalScope
    let pendingDailyCount: Int
    let pendingOtherCount: Int
    let onApply: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 6)
                .padding(.top, 16)

            VStack(alignment: .leading, spacing: 8) {
                Text("live activity")
                    .font(.custom("Gaegu-Regular", size: 32))
                Text("Sleek lock-screen view with daily priority first.")
                    .font(.custom("Gaegu-Regular", size: 18))
                    .foregroundStyle(Color.capyBrown.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)

            Toggle(isOn: $isEnabled) {
                Text("Enable live activity")
                    .font(.custom("Gaegu-Regular", size: 22))
            }
            .tint(Color.green)
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 10) {
                Text("Mode")
                    .font(.custom("Gaegu-Regular", size: 20))
                Picker("Mode", selection: $mode) {
                    ForEach(CapyLiveActivityMode.allCases, id: \.self) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                Text(mode.subtitle)
                    .font(.custom("Gaegu-Regular", size: 17))
                    .foregroundStyle(Color.capyBrown.opacity(0.82))
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 10) {
                Text("Goals shown after daily priority")
                    .font(.custom("Gaegu-Regular", size: 20))
                Picker("Goal scope", selection: $goalScope) {
                    ForEach(CapyLiveActivityGoalScope.allCases, id: \.self) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                Text(goalScope.subtitle)
                    .font(.custom("Gaegu-Regular", size: 17))
                    .foregroundStyle(Color.capyBrown.opacity(0.82))
            }
            .padding(.horizontal, 20)

            Text("Pending now: \(pendingDailyCount) daily, \(pendingOtherCount) other goals.")
                .font(.custom("Gaegu-Regular", size: 18))
                .foregroundStyle(Color.capyBrown.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            Button {
                let feedback = UINotificationFeedbackGenerator()
                feedback.notificationOccurred(isEnabled ? .success : .warning)
                onApply()
                dismiss()
            } label: {
                Text(isEnabled ? "Save and enable" : "Save and disable")
                    .font(.custom("Gaegu-Regular", size: 24))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isEnabled ? Color.capyBlue : Color.gray.opacity(0.55))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 4)
        }
    }
}

private struct CapyShopSheet: View {
    let dayLabel: String
    let balance: Int
    let items: [CapyShopItem]
    let isPurchased: (CapyShopItem) -> Bool
    let onBuy: (CapyShopItem) -> Void

    var body: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 6)
                .padding(.top, 8)

            HStack {
                Text("CapyShop")
                    .font(.custom("Gaegu-Regular", size: 28))
                    .foregroundStyle(Color.capyDarkBrown)
                Spacer()
                
                Text("🪙")
                    .font(.custom("Gaegu-Regular", size: 24))
                    .padding(.top, 2)
                Text(String(balance))
                    .font(.custom("Gaegu-Regular", size: 28))
                    .foregroundStyle(Color.capyDarkBrown)
            }
            .padding(.horizontal, 20)
            
            Text("care drop for your capy: \(dayLabel)")
                .font(.custom("Gaegu-Regular", size: 17))
                .foregroundStyle(Color.capyBrown.opacity(0.75))
                .padding(.horizontal, 20)

//            VStack(alignment: .leading, spacing: 3) {
//                Text("how to buy: tap a \"buy\" button.")
//                Text("what it does: each item shows an effect (+1 stat or cosmetic only).")
//            }
//            .font(.custom("Gaegu-Regular", size: 16))
//            .foregroundStyle(Color.capyBrown.opacity(0.8))
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .padding(.horizontal, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(items) { item in
                        HStack(spacing: 12) {
                            Text(item.emoji)
                                .font(.system(size: 30))

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.title)
                                        .font(.custom("Gaegu-Regular", size: 22))
                                        .foregroundStyle(Color.capyDarkBrown)
                                    Text(effectText2(for: item))
                                        .font(.custom("Gaegu-Regular", size: 18))
                                        .foregroundStyle(Color.capyBrown)
                                        .opacity(0.8)
                                }
                                Text(item.description)
                                    .font(.custom("Gaegu-Regular", size: 16))
                                    .foregroundStyle(Color.capyBrown.opacity(0.78))
//                                Text(effectText(for: item))
//                                    .font(.custom("Gaegu-Regular", size: 15))
//                                    .foregroundStyle(Color.capyDarkBrown.opacity(0.78))
                            }

                            Spacer()

                            let purchased = isPurchased(item)
                            Button {
                                onBuy(item)
                            } label: {
                                Text(purchased ? "bought today" : "buy \(item.cost)")
                                    .font(.custom("Gaegu-Regular", size: 18))
                                    .foregroundStyle(purchased ? Color.capyBrown.opacity(0.5) : Color.capyBrown)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.92))
                                    .clipShape(Capsule())
                            }
                            .disabled(purchased)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    Text("new items appear daily at midnight.")
                        .font(.custom("Gaegu-Regular", size: 18))
                        .foregroundStyle(Color.capyBrown.opacity(0.75))
                        .padding(.vertical, 14)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color.capyBeige.opacity(0.96))
    }

    private func effectText(for item: CapyShopItem) -> String {
        guard let stat = item.statReward else {
            return "effect: cosmetic only (no stat boost)"
        }
        switch stat {
        case "🍋":
            return "effect: +1 energy (🍋)"
        case "🛁":
            return "effect: +1 hygiene (🛁)"
        case "😁":
            return "effect: +1 mood (😁)"
        default:
            return "effect: +1 stat (\(stat))"
        }
    }
    
    private func effectText2(for item: CapyShopItem) -> String {
        guard let stat = item.statReward else { return "" }
        return "(+\(stat))"
    }
}

struct ExplodingCoinModifier: ViewModifier {
    let coin: FlyingCoin
    var onComplete: () -> Void

    @State private var isVisible = false
    @State private var isExploded = false
    @State private var isMagnetized = false
    
    var currentPosition: CGPoint {
        if isMagnetized {
            return coin.endPosition
        } else if isExploded {
            return CGPoint(
                x: coin.startPosition.x + coin.explodeOffset.width,
                y: coin.startPosition.y + coin.explodeOffset.height
            )
        } else {
            return coin.startPosition
        }
    }

    func body(content: Content) -> some View {
        content
            .position(currentPosition)
            .opacity(isVisible ? 1 : 0)
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
    HomeView2(store: CapyStore())
}
