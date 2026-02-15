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
        CapyShopItem(id: "watermelon_bowl", emoji: "🍉", title: "Watermelon", description: "Fresh fruit serving for your capy’s mood.", cost: 32, statReward: "😁"),
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
    @State private var popProgress: CGFloat = 0
    @State private var isSpinning = false
    private let rotationDuration = 12.0

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
        let currentRadius = (ringDiameter / 2) * (0.16 + 0.84 * popProgress)

        ZStack {
            ForEach(Array(chars.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(.custom("Gaegu-Bold", size: 9))
                    .foregroundStyle(.white.opacity(0.98))
                    .offset(y: -currentRadius)
                    .rotationEffect(.degrees(Double(index) * step))
            }
        }
        .frame(width: ringDiameter + 18, height: ringDiameter + 18)
        .rotationEffect(.degrees(isSpinning ? 360 : 0))
        .scaleEffect(0.82 + 0.18 * popProgress)
        .opacity(popProgress)
        .blur(radius: (1 - popProgress) * 1.6)
        .onAppear {
            popProgress = 0
            isSpinning = false
            withAnimation(.spring(response: 0.52, dampingFraction: 0.76)) {
                popProgress = 1
            }
            withAnimation(.linear(duration: rotationDuration).repeatForever(autoreverses: false)) {
                isSpinning = true
            }
        }
        .onDisappear {
            popProgress = 0
            isSpinning = false
        }
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

    @AppStorage("user_name") private var userName = "bro"
    @AppStorage("capy_shop_last_day_key") private var shopLastDayKey = ""
    @AppStorage("capy_shop_purchased_ids") private var purchasedShopItemsCSV = ""
    @AppStorage("capy_last_goal_checkin_ts") private var lastGoalCheckInTimestamp = 0.0
    @AppStorage("capy_last_wake_day_key") private var lastWakeDayKey = ""
    @AppStorage("capy_live_activity_enabled") private var liveActivityEnabled = false
    @AppStorage("capy_live_activity_mode") private var liveActivityModeRaw = CapyLiveActivityMode.capyCare.rawValue
    @AppStorage("capy_live_activity_goal_scope") private var liveActivityGoalScopeRaw = CapyLiveActivityGoalScope.allGoals.rawValue
    
    @AppStorage("capy_stat_energy") private var storedEnergy: Double = 2.0
    @AppStorage("capy_stat_hygiene") private var storedHygiene: Double = 3.0
    @AppStorage("capy_stat_mood") private var storedMood: Double = 3.0
    @AppStorage("capy_last_decay_ts") private var lastDecayTimestamp: Double = Date().timeIntervalSince1970
    @AppStorage("capy_reminders_enabled") private var remindersEnabled = false
    @AppStorage("capy_daily_review_reminder_minutes") private var dailyReviewReminderMinutes = 20 * 60
    @AppStorage("capy_weekly_review_reminder_minutes") private var weeklyReviewReminderMinutes = 18 * 60
    @AppStorage("capy_weekly_review_reminder_weekday") private var weeklyReviewReminderWeekday = 1

    @State private var showAddAlert = false
    @State private var newTaskText = ""

    private var stats: [StatItem] {
        [
            StatItem(emoji: "🍋", points: storedEnergy),
            StatItem(emoji: "🛁", points: storedHygiene),
            StatItem(emoji: "😁", points: storedMood)
        ]
    }
    
    @State private var balanceDisplay: Double = 0.0
    @State private var flyingCoins: [FlyingCoin] = []
    @State private var audioPlayer: AVAudioPlayer?
    
    @State private var micTapped: Bool = false
    
    @State private var isCollectingCoins = false

    @State private var taskToEdit: CapyTask?
    @State private var showActionSheet = false
    @State private var showEditAlert = false
    @State private var editTaskText = ""
    @State private var selectedFrequency: TaskFrequency = .daily

    @State private var showShopSheet = false
    @State private var showChallengeSheet = false
    @State private var showLiveActivitySheet = false
    @State private var showReviewSheet = false
    @State private var shopItems: [CapyShopItem] = []
    @State private var currentShopDayKey = ""
    @State private var showShopAlert = false
    @State private var shopAlertMessage = ""
    @State private var showReminderAlert = false
    @State private var reminderAlertMessage = ""

    @State private var capyText = "yo bro, i'm capy. tap capyshop if you wanna grab me care stuff."
    
    @State private var showChatInput = false
    @State private var chatInputText = ""
    @FocusState private var isChatFocused: Bool
    @State private var thinkingState: ThinkingState = .none
    @State private var keyboardHeight: CGFloat = 0
    @State private var coinIconTarget: CGPoint = .zero
    
    @State private var isCapySleeping = false
    @State private var lastSessionGoalCheckInDate = Date.distantPast
    
    @State private var bouncingDecorationID: String? = nil

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
    
    private var isCapyCrying: Bool {
        stats.contains { $0.points <= 0 }
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
                    .offset(y: (keyboardHeight > 0 && isChatFocused) ? -(keyboardHeight-20) : 0)
                    .animation(.easeInOut(duration: 0.5), value: keyboardHeight)
                    .zIndex(10)
                    .onTapGesture {
                        if showChatInput {
                            closeChat()
                        }
                    }
                    .ignoresSafeArea()
                
                chatInterfaceLayer
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .zIndex(20)
            }
            .coordinateSpace(name: "homeLayer")
            .overlay(coinsLayer)
        }
    }
    
    private var shopSheetContent: some View {
        CapyShopSheet(
            dayLabel: shopDayLabel(from: currentShopDayKey),
            balance: store.stats.coins,
            freezeCount: store.stats.freezeProtectors,
            freezeCost: CapyStore.freezeProtectorCost,
            items: shopItems,
            isPurchased: { isPurchased($0) },
            onBuy: { buyShopItem($0) },
            onBuyFreeze: {
                if store.stats.freezeProtectors >= 2 {
                    shopAlertMessage = "you can only hold 2 freeze protectors at a time."
                    showShopAlert = true
                    return false
                }
                if store.buyFreezeProtector() {
                    capyText = "freeze protector stocked. streak safety is now x\(store.stats.freezeProtectors)."
                    return true
                } else {
                    shopAlertMessage = "not enough coins for a freeze protector."
                    showShopAlert = true
                    return false
                }
            },
            onReset: {
                purchasedShopItemsCSV = ""
                shopLastDayKey = ""
                store.awardBonusCoins(100)
                updateStat(emoji: "😁", change: 1)
                updateStat(emoji: "🛁", change: 1)
                updateStat(emoji: "🍋", change: 1)
                refreshDailyShopIfNeeded(force: true)
//                shopItems = Array(CapyShopItem.catalog.shuffled().prefix(5))
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            },
            onUnlockAll: {
                let allIDs = CapyShopItem.catalog.map { $0.id }
                purchasedShopItemsCSV = allIDs.joined(separator: ",")
                store.awardBonusCoins(500)
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            },
            onRefillStats: {
                withAnimation {
                    storedEnergy = 5.0
                    storedHygiene = 5.0
                    storedMood = 5.0
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            },
            onClearFreezes: {
                store.debugClearFreezes()
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private var challengeSheetContent: some View {
        ChallengeSheet(
            store: store,
            challenge: $store.challenge,
            balance: store.stats.coins,
            onStart: { length in
                store.startChallenge(length)
                capyText = "challenge started: \(length.title). check in every day."
            }
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private var settingsSheetContent: some View {
        SettingsSheet(
            userName: $userName,
            isEnabled: $liveActivityEnabled,
            mode: liveActivityModeSelection,
            goalScope: liveActivityGoalScopeSelection,
            remindersEnabled: $remindersEnabled,
            dailyReminderMinutes: $dailyReviewReminderMinutes,
            weeklyReminderMinutes: $weeklyReviewReminderMinutes,
            weeklyReminderWeekday: $weeklyReviewReminderWeekday,
            pendingDailyCount: pendingDailyTasks.count,
            pendingOtherCount: pendingNonDailyTasks.count
        ) {
            syncReminders()
            syncLiveActivity()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private var reviewSheetContent: some View {
        ReviewSheet(store: store)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
    }

    var body: some View {
        logicLayer
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
            .alert("Reminders", isPresented: $showReminderAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(reminderAlertMessage)
            }
            .sheet(isPresented: $showShopSheet) {
                shopSheetContent
            }
            .sheet(isPresented: $showChallengeSheet) {
                challengeSheetContent
            }
            .sheet(isPresented: $showLiveActivitySheet) {
                settingsSheetContent
            }
            .sheet(isPresented: $showReviewSheet) {
                reviewSheetContent
            }
    }
    
    private var logicLayer: some View {
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
        
        .onAppear {
            let resetMessages = store.resetDailyIfNeeded()
            balanceDisplay = Double(store.stats.coins)
            refreshDailyShopIfNeeded(force: true)
            refreshCapySleepState()
            syncReminders()
            syncLiveActivity()
            checkDecay()
            if let message = resetMessages.last {
                capyText = message
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                let resetMessages = store.resetDailyIfNeeded()
                checkDecay()
                refreshDailyShopIfNeeded()
                refreshCapySleepState()
                if let message = resetMessages.last {
                    capyText = message
                }
            }
            syncLiveActivity(isAwayOverride: newPhase != .active)
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
            let resetMessages = store.resetDailyIfNeeded()
            if let message = resetMessages.last {
                capyText = message
            }
            refreshCapySleepState()
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
        .padding(.bottom, (keyboardHeight > 0 && isChatFocused) ? keyboardHeight : (showChatInput ? 0 : 30))
        .animation(.easeInOut(duration: 0.5), value: keyboardHeight)
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
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading) {
                Button {
                    refreshDailyShopIfNeeded()
                    showShopSheet = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
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
                }
                
                Button {
                    showReviewSheet = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: 4) {
                        Text("lvl \(store.progressionLevel)")
                            .font(.custom("Gaegu-Regular", size: 20))
                        Text(store.progressionTitle)
                            .font(.custom("Gaegu-Regular", size: 16))
                            .lineLimit(1)
                    }
                    .foregroundStyle(Color.capyDarkBrown)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.9))
                    .clipShape(Capsule())
                }
            }
            .padding(.leading, 12)
            
            Spacer()
            
            HStack(spacing: -20) {
//                
//                Button{
//                    HapticEngine.shared.playCoinShower()
//                } label: {
//                    ZStack {
//                        Circle()
//                            .fill(Color.capyBlue)
//                            .frame(width: 50, height: 50)
//                            .shadow(radius: 4)
//                        
//                        Text("a")
//                            .font(.custom("Gaegu-Regular", size: 22))
//                            .foregroundStyle(.white)
//                    }
//                    .frame(width: 50, height: 50)
//                }
//                .frame(width: 80, height: 80, alignment: .bottom)
//                .contentShape(Rectangle())
//                
//                Button{
//                    HapticEngine.shared.playDoubleThud()
//                } label: {
//                    ZStack {
//                        Circle()
//                            .fill(Color.capyBlue)
//                            .frame(width: 50, height: 50)
//                            .shadow(radius: 4)
//                        
//                        Text("a")
//                            .font(.custom("Gaegu-Regular", size: 22))
//                            .foregroundStyle(.white)
//                    }
//                    .frame(width: 50, height: 50)
//                }
//                .frame(width: 80, height: 80, alignment: .bottom)
//                .contentShape(Rectangle())
//                
//                Button{
//                    HapticEngine.shared.playPurr()
//                } label: {
//                    ZStack {
//                        Circle()
//                            .fill(Color.capyBlue)
//                            .frame(width: 50, height: 50)
//                            .shadow(radius: 4)
//                        
//                        Text("a")
//                            .font(.custom("Gaegu-Regular", size: 22))
//                            .foregroundStyle(.white)
//                    }
//                    .frame(width: 50, height: 50)
//                }
//                
//                Button{
//                    HapticEngine.shared.playCustomTexture()
//                } label: {
//                    ZStack {
//                        Circle()
//                            .fill(Color.capyBlue)
//                            .frame(width: 50, height: 50)
//                            .shadow(radius: 4)
//                        
//                        Text("a")
//                            .font(.custom("Gaegu-Regular", size: 22))
//                            .foregroundStyle(.white)
//                    }
//                    .frame(width: 50, height: 50)
//                }
//                .frame(width: 80, height: 80, alignment: .bottom)
//                .contentShape(Rectangle())
                
                Button(action: handleMicTap) {
                    ZStack {
                        Circle()
                            .fill(Color.capyBlue)
                            .frame(width: 50, height: 50)
                            .shadow(radius: 4)
                        
                        if speechRecognizer.isRecording || micTapped {
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
                    .frame(width: 50, height: 50)
                    .background {
                        if speechRecognizer.isRecording {
                            CircularTranscriptRing(transcript: speechRecognizer.transcript)
                        }
                    }
                }
                .frame(width: 80, height: 80, alignment: .bottom)
                .contentShape(Rectangle())
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
                .frame(width: 80, height: 80, alignment: .bottom)
                .contentShape(Rectangle())
                .disabled(isCapySleeping || thinkingState != .none)
                .opacity(isCapySleeping ? 0.6 : 1.0)
            }
        }
        .padding(.horizontal, 8)
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
            HStack(spacing: 8) {
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

//                if store.challenge.isActive {
//                    Text("🏁 \(store.challenge.completedCheckIns)/\(store.challenge.length.rawValue)")
//                        .font(.custom("Gaegu-Regular", size: 18))
//                        .foregroundStyle(Color.capyDarkBrown)
//                        .padding(.horizontal, 8)
//                        .padding(.vertical, 6)
//                        .background(.white.opacity(0.92))
//                        .clipShape(Capsule())
//                }
            }
            
            Spacer()

            HStack(spacing: 10) {
//                Button {
//                    showReviewSheet = true
//                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                } label: {
//                    HStack(spacing: 6) {
//                        Image(systemName: "doc.text.magnifyingglass")
////                        Text("review")
////                            .font(.custom("Gaegu-Regular", size: 20))
//                    }
//                    .foregroundStyle(Color.capyDarkBrown)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 6)
//                    .background(.white.opacity(0.92))
//                    .clipShape(Capsule())
//                }

                Button {
                    showChallengeSheet = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: 4) {
                        if store.challenge.isActive {
                            let isDoneToday = Calendar.current.isDateInToday(store.challenge.lastCheckInDate ?? .distantPast)
                            
                            Text("🔥")
                                .font(.system(size: 16))
                                .saturation(isDoneToday ? 1 : 0)
                                .opacity(isDoneToday ? 1 : 0.6)
                            //                            .padding(.bottom, 2)
                            
                            Text("\(store.challenge.completedCheckIns)/\(store.challenge.length.rawValue)")
                                .font(.custom("Gaegu-Regular", size: 20))
                                .foregroundStyle(Color.capyDarkBrown)
                        } else {
                            Text("🎯 challenge")
                                .font(.custom("gaegu-Regular", size: 16))
                                .foregroundStyle(Color.capyDarkBrown)
//                                .saturation(0)
//                                .opacity(0.6)
                        }
                    }
                    .foregroundStyle(Color.capyDarkBrown)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 9)
                    .background(.white.opacity(0.92))
                    .clipShape(Capsule())
                }
                
                Button {
                    showLiveActivitySheet = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: 6) {
//                        Circle()
//                            .fill(liveActivityEnabled ? Color.green : Color.gray.opacity(0.5))
//                            .frame(width: 8, height: 8)
//                        Text(liveActivityEnabled ? liveActivityMode.shortLabel : "live")
//                            .font(.custom("Gaegu-Regular", size: 20))
                        Image(systemName: "gearshape.fill")
                    }
                    .foregroundStyle(Color.capyDarkBrown)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.92))
                    .clipShape(Capsule())
                }

//                Button {
//                    refreshDailyShopIfNeeded()
//                    showShopSheet = true
//                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                } label: {
//                    HStack(spacing: 6) {
//                        Image(systemName: "storefront.fill")
////                        Text("capyshop")
////                            .font(.custom("Gaegu-Regular", size: 20))
//                    }
//                    .foregroundStyle(Color.capyDarkBrown)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 8)
//                    .background(.white.opacity(0.92))
//                    .clipShape(Capsule())
//                }
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
                                    .padding(.vertical, 2)
                                    .contentShape(Rectangle())
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
                    .scrollDisabled(filteredTasks.count <= 5)
                }

                Button(action: {
                    newTaskText = ""
                    showAddAlert = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                    ScrollView(.vertical, showsIndicators: true) {
                        Text(capyText)
                            .font(.custom("Gaegu-Regular", size: 21))
                            .foregroundStyle(Color.capyDarkBrown)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

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
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
                .frame(maxHeight: .infinity)
            }
            .frame(height: 135)
            .padding(.horizontal, 20)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: capyText)
            
            
            ZStack {
                Image(isCapyCrying ? "capy_cry" : isCapySleeping ? "capy_sleep" : "capy_sit")
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width + 4)
//                .padding(.bottom, 10)
//                .onTapGesture {
//                    if !showChatInput {
//                        handleCapyTap()
//                    }
//                }
                
                Capsule()
                    .fill(Color.black.opacity(0.001))
                    .frame(width: 220, height: 170)
                    .offset(y: -50)
                
                    .onTapGesture {
                        if !showChatInput {
                            handleCapyTap()
                        } else {
                            closeChat()
                        }
                    }
                
                ForEach(Array(purchasedItemIDs), id: \.self) { id in
                    if let config = getDecorationConfig(for: id) {
                        Text(config.emoji)
                            .font(.system(size: 20))
                            .scaleEffect(config.scale)
                            .scaleEffect(bouncingDecorationID == id ? 1.3 : 1.0)
                            .rotationEffect(.degrees(config.rotation))
                            .rotationEffect(.degrees(bouncingDecorationID == id ? -10 : 0))
                            .offset(config.offset)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                            .onTapGesture {
                                handleDecorationTap(id: id, sound: config.soundName)
                            }
                    }
                }
                
//                    .overlay {
//                        GeometryReader { geo in
//                            ZStack {
//                                Capsule()
//                                    .fill(Color.black.opacity(0.001))
//                                    .frame(width: 220, height: 170)
//                                    .position(x: geo.size.width / 2, y: geo.size.height / 2 - 70)
//                                    .onTapGesture {
//                                        if !showChatInput {
//                                            handleCapyTap()
//                                        } else {
//                                            closeChat()
//                                        }
//                                    }
//                            }
//                        }
//                    }
            }
            .padding(.bottom, (keyboardHeight > 0 && isChatFocused) ? keyboardHeight/2 : 60)
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
            let oldLevel = store.progressionLevel
            
            let toggleResult = store.toggleTask(task)
            let newLevel = store.progressionLevel
            
            let rewardAmount = task.coinReward
            let rewardStat = task.statReward
            
            triggerReward(at: location, amount: rewardAmount)
            if let stat = rewardStat { updateStat(emoji: stat, change: 1) }
            if let challengeMessage = toggleResult.challengeMessage {
                capyText = challengeMessage
            } else if newLevel > oldLevel {
                capyText = "level up! you're now lvl \(newLevel) (\(store.progressionTitle))."
            } else {
                capyText = "nice work bro, you finished \"\(task.title)\"."
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isCollectingCoins = false
                withAnimation {
                    balanceDisplay = Double(store.stats.coins)
                }
            }
        } else {
            _ = store.toggleTask(task)
            
            let rewardStat = task.statReward
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            if let stat = rewardStat { updateStat(emoji: stat, change: -1) }
            capyText = "all good bro, we can take another shot at \"\(task.title)\"."
        }
    }

    private func updateStat(emoji: String, change: Double) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        withAnimation {
            switch emoji {
            case "🍋":
                storedEnergy = min(max(storedEnergy + change, 0), 5)
            case "🛁":
                storedHygiene = min(max(storedHygiene + change, 0), 5)
            case "😁":
                storedMood = min(max(storedMood + change, 0), 5)
            default:
                break
            }
        }
        
//        if let index = stats.firstIndex(where: { $0.emoji == emoji }) {
//            withAnimation {
//                let newPoints = stats[index].points + change
//                stats[index].points = min(max(newPoints, 0), 5)
//            }
//        }
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
        
        let newGoalTitle = newTaskText

        withAnimation {
            store.addTask(title: newTaskText, frequency: selectedFrequency)
        }
        
        HapticEngine.shared.playDoubleThud()
        
        newTaskText = ""
        
        thinkingState = .text
        
        Task {
            let reply = await brain.coachReply(
                userMessage: "i just added a new goal called \"\(newGoalTitle)\". give me a super short, chill confirmation",
                goals: pendingTasks.map { $0.title },
                completedCount: store.tasks.filter { $0.isDone }.count,
                pendingCount: pendingTasks.count
            )
            
            await MainActor.run {
                capyText = reply
                thinkingState = .none
            }
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
//            shopAlertMessage = "bought \(item.title.lowercased()). \(effectText) capyshop refreshes at midnight."
//            showShopAlert = true
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
            "yo \(userName), how's \"{goal}\" feeling right now?",
            "no pressure \(userName), got a tiny move for \"{goal}\"?",
            "if you want, we can do a 10-minute step on \"{goal}\".",
            "what would make \"{goal}\" easier tonight, \(userName)?"
        ]

        let template = prompts.randomElement() ?? "how's \"{goal}\" going, bro?"
        capyText = template.replacingOccurrences(of: "{goal}", with: targetTask.title)
        lastSessionGoalCheckInDate = now
        lastGoalCheckInTimestamp = now.timeIntervalSince1970
    }
    
    private func openChat() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        chatInputText = ""
        withAnimation {
            showChatInput = true
            isChatFocused = true
        }
    }
    
    private func closeChat() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation {
            showChatInput = false
            isChatFocused = false
        }
    }

    private func sendMessageToCapy() {
        HapticEngine.shared.playDoubleThud()
        
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
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if speechRecognizer.isRecording {
            speechRecognizer.stopTranscribing()
        } else {
            micTapped = true
            let start = {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.125) {
                    speechRecognizer.startTranscribing()
                    micTapped = false
                }
            }
            
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
        HapticEngine.shared.playDoubleThud()
    }
    
    private func processCoachReply(message: String) {
        let context = capyContextForFeeling()
//        thinkingState = .text
//        capyText = ""
        
        Task {
            let stream = brain.streamCoachReply(
                userMessage: message,
                goals: pendingTasks.map { $0.title },
                completedCount: store.tasks.filter { $0.isDone }.count,
                pendingCount: pendingTasks.count,
                extraContext: context
            )
            
            var isFirstChunk = true
            
            for try await chunk in stream {
                if chunk.isEmpty { continue }
                
                await MainActor.run {
                    if isFirstChunk {
                        capyText = ""
                        isFirstChunk = false
                    }
                    capyText += chunk
                    
                    let generator = UISelectionFeedbackGenerator()
                    generator.prepare()
                    generator.selectionChanged()
                }
            }
            
            await MainActor.run {
                thinkingState = .none
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
        user name: \(userName).
        capy state: \(isCapySleeping ? "sleepy" : "awake").
        coins: \(Int(balanceDisplay)).
        freeze protectors: \(store.stats.freezeProtectors).
        challenge: \(store.challenge.isActive ? "\(store.challenge.length.title) \(store.challenge.completedCheckIns)/\(store.challenge.length.rawValue)" : "none active").
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

    private func syncReminders() {
        Task {
            await ReminderScheduler.shared.syncReminders(
                isEnabled: remindersEnabled,
                dailyReminderMinutes: dailyReviewReminderMinutes,
                weeklyReminderMinutes: weeklyReviewReminderMinutes,
                weeklyWeekday: weeklyReviewReminderWeekday
            )

            if remindersEnabled {
                let granted = await ReminderScheduler.shared.requestPermissionIfNeeded()
                if !granted {
                    await MainActor.run {
                        remindersEnabled = false
                        reminderAlertMessage = "notifications are off in iOS settings, so reminders were not enabled."
                        showReminderAlert = true
                    }
                }
            }
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
    
    private func checkDecay() {
        let now = Date().timeIntervalSince1970
        let hoursPassed = (now - lastDecayTimestamp) / 3600.0
        
        let decayRateHours: Double = 4.0
        
        if hoursPassed >= decayRateHours {
            let pointsToLose = Int(hoursPassed / decayRateHours)
            
            if pointsToLose > 0 {
                withAnimation {
                    storedEnergy = max(storedEnergy - Double(pointsToLose), 0)
                    storedHygiene = max(storedHygiene - Double(pointsToLose), 0)
                    storedMood = max(storedMood - Double(pointsToLose), 0)
                }
                
                lastDecayTimestamp = now
                print("Capy stats decayed by \(pointsToLose) points after \(String(format: "%.1f", hoursPassed)) hours")
            }
        }
    }
    
    struct CapyDecoration {
        let emoji: String
        let offset: CGSize
        let scale: CGFloat
        let soundName: String?
        let rotation: Double
    }
    
    private func getDecorationConfig(for id: String) -> CapyDecoration? {
        switch id {
        case "sun_hat":
            return CapyDecoration(emoji: "👒", offset: CGSize(width: 10, height: -130), scale: 3.5, soundName: "cloth", rotation: -5)
        case "river_toy":
            return CapyDecoration(emoji: "🦆", offset: CGSize(width: 160, height: -125), scale: 2.5, soundName: "quack", rotation: 0)
        case "citrus_treats":
            return CapyDecoration(emoji: "🍋", offset: CGSize(width: 140, height: 25), scale: 2.0, soundName: "chomp", rotation: 0)
        case "watermelon_bowl":
            return CapyDecoration(emoji: "🍉", offset: CGSize(width: 170, height: -20), scale: 2.2, soundName: "chomp", rotation: -10)
        case "cozy_lantern":
            return CapyDecoration(emoji: "🏮", offset: CGSize(width: -105, height: -130), scale: 2.5, soundName: "click", rotation: 5)
        case "rain_boots":
            return CapyDecoration(emoji: "🥾", offset: CGSize(width: 35, height: 90), scale: 1.8, soundName: "stomp", rotation: 15)
        case "bubble_bath":
            return CapyDecoration(emoji: "🫧", offset: CGSize(width: -90, height: 30), scale: 2.0, soundName: "pop", rotation: -10)
        case "grooming_kit":
            return CapyDecoration(emoji: "🪮", offset: CGSize(width: -100, height: -40), scale: 2.0, soundName: "brush", rotation: -20)
        case "soft_blanket":
            return CapyDecoration(emoji: "🧺", offset: CGSize(width: -20, height: 90), scale: 2.0, soundName: "cloth", rotation: 0)
        case "leaf_salad":
            return CapyDecoration(emoji: "🥬", offset: CGSize(width: 145, height: -65), scale: 2.0, soundName: "chomp", rotation: 10)
        case "reed_mat":
            return CapyDecoration(emoji: "🧶", offset: CGSize(width: -55, height: 10), scale: 2.0, soundName: "cloth", rotation: 0)
        case "pond_pass":
            return CapyDecoration(emoji: "🎟️", offset: CGSize(width: -155, height: -130), scale: 2.0, soundName: "paper", rotation: 15)
        default:
            return nil
        }
    }
    
    private func handleDecorationTap(id: String, sound: String?) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.2)) {
            bouncingDecorationID = id
        }
        
        if let soundName = sound {
            playSound(name: soundName, fileExtension: "mp3")
        }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        requestItemReaction(itemID: id)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                bouncingDecorationID = nil
            }
        }
    }
    
    private func getShopItemTitle(id: String) -> String {
        return CapyShopItem.catalog.first(where: { $0.id == id })?.title ?? "thing"
    }
    
    private func requestItemReaction(itemID: String) {
        guard thinkingState == .none else { return }
        
        let itemTitle = getShopItemTitle(id: itemID)
        let context = capyContextForFeeling()
        
        thinkingState = .text
        
        Task {
            let reply = await brain.coachReply(
                userMessage: "system note: user just tapped/poked your '\(itemTitle)'. give a specific, chill reaction to this item. keep it very short (max 1 sentence). lowercase.",
                goals: pendingTasks.map { $0.title },
                completedCount: store.tasks.filter { $0.isDone }.count,
                pendingCount: pendingTasks.count,
                extraContext: context
            )
            
            await MainActor.run {
                withAnimation {
                    capyText = reply
                    thinkingState = .none
                }
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}

private struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var userName: String
    @Binding var isEnabled: Bool
    @Binding var mode: CapyLiveActivityMode
    @Binding var goalScope: CapyLiveActivityGoalScope
    @Binding var remindersEnabled: Bool
    @Binding var dailyReminderMinutes: Int
    @Binding var weeklyReminderMinutes: Int
    @Binding var weeklyReminderWeekday: Int
    
    @Namespace private var animationNamespace
    
    let pendingDailyCount: Int
    let pendingOtherCount: Int
    let onApply: () -> Void

    private let weekdayOptions: [(value: Int, title: String)] = [
        (1, "sunday"),
        (2, "monday"),
        (3, "tuesday"),
        (4, "wednesday"),
        (5, "thursday"),
        (6, "friday"),
        (7, "saturday")
    ]

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 6)
                .padding(.top, 16)
            
            Text("settings")
                .font(.custom("Gaegu-Regular", size: 32))
                .foregroundStyle(Color.capyDarkBrown)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .trailing) {
                    Button("done") {
                        let feedback = UINotificationFeedbackGenerator()
                        feedback.notificationOccurred(.success)
                        onApply()
                        dismiss()
                    }
                    .font(.custom("Gaegu-Regular", size: 20))
                    .foregroundStyle(Color.capyBlue)
                    .padding(.trailing, 24)
                    .padding(.top, 4)
                }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Name")
                                .font(.custom("Gaegu-Regular", size: 22))
                                .foregroundStyle(Color.capyDarkBrown)
                            Spacer()
                            TextField("Your name", text: $userName)
                                .font(.custom("Gaegu-Regular", size: 22))
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(Color.gray)
                        }
                        .padding(16)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
                    
                    VStack(spacing: 0) {
                        Toggle(isOn: $remindersEnabled.animation(.spring(response: 0.35, dampingFraction: 0.7))) {
                            Text("Reminders")
                                .font(.custom("Gaegu-Regular", size: 22))
                                .foregroundStyle(Color.capyDarkBrown)
                        }
                        .tint(Color.capyBlue)
                        .padding(16)
                        .zIndex(1)
                        
//                        if remindersEnabled {
                            VStack(spacing: 0) {
                                Divider().padding(.horizontal, 16)
                                
                                VStack(spacing: 18) {
                                    HStack {
                                        Text("Daily Review")
                                            .font(.custom("Gaegu-Regular", size: 18))
                                            .foregroundStyle(Color.capyBrown)
                                        Spacer()
                                        DatePicker("", selection: timeBinding(minutes: $dailyReminderMinutes), displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                            .scaleEffect(0.85)
                                    }
                                    
                                    HStack {
                                        Text("Weekly Review")
                                            .font(.custom("Gaegu-Regular", size: 18))
                                            .foregroundStyle(Color.capyBrown)
                                        Spacer()
                                        
                                        HStack(spacing: -4) {
                                            Picker("", selection: $weeklyReminderWeekday) {
                                                ForEach(weekdayOptions, id: \.value) { option in
                                                    Text(option.title).tag(option.value)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .scaleEffect(0.85)
                                            .labelsHidden()
                                            .padding(.leading, -16)
                                            
                                            DatePicker("", selection: timeBinding(minutes: $weeklyReminderMinutes), displayedComponents: .hourAndMinute)
                                                .labelsHidden()
                                                .scaleEffect(0.85)
                                        }
                                    }
                                }
                                .padding(16)
                                //                            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                            }
//                            .compositingGroup()
//                            .transition(.opacity)
                            .frame(height: remindersEnabled ? nil : 0, alignment: .top)
                            .opacity(remindersEnabled ? 1 : 0)
                            .clipped()
//                        }
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: remindersEnabled)
                    
                    VStack(spacing: 0) {
                        Toggle(isOn: $isEnabled) {
                            Text("Live Activity")
                                .font(.custom("Gaegu-Regular", size: 22))
                                .foregroundStyle(Color.capyDarkBrown)
                        }
                        .tint(Color.capyBlue)
                        .padding(16)
                        
                        if isEnabled {
                            Divider().padding(.horizontal, 16)
                            
                            VStack(spacing: 16) {
                                CapySegmentedPicker(
                                    options: CapyLiveActivityMode.allCases,
                                    selection: $mode,
                                    title: \.title,
                                    namespace: animationNamespace,
                                    namespaceId: "mode_slide"
                                )
                                
                                CapySegmentedPicker(
                                    options: CapyLiveActivityGoalScope.allCases,
                                    selection: $goalScope,
                                    title: \.title,
                                    namespace: animationNamespace,
                                    namespaceId: "goalscope_slide"
                                )
                                
//                                Text("Pending: \(pendingDailyCount) daily, \(pendingOtherCount) others")
//                                    .font(.custom("Gaegu-Regular", size: 14))
//                                    .foregroundStyle(.gray.opacity(0.6))
//                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(16)
                        }
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isEnabled)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.capyBeige.opacity(0.98))
    }
    
    private func timeBinding(minutes: Binding<Int>) -> Binding<Date> {
        Binding<Date>(
            get: {
                let clamped = max(0, min(minutes.wrappedValue, 23 * 60 + 59))
                let hour = clamped / 60
                let minute = clamped % 60
                var components = DateComponents()
                components.hour = hour
                components.minute = minute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                let hour = parts.hour ?? 0
                let minute = parts.minute ?? 0
                minutes.wrappedValue = (hour * 60) + minute
            }
        )
    }
}

struct CapySegmentedPicker<T: Hashable>: View {
    let options: [T]
    @Binding var selection: T
    let title: (T) -> String
    let namespace: Namespace.ID
    let namespaceId: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection == option
                
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selection = option
                } label: {
                    Text(title(option))
                        .font(.custom("Gaegu-Regular", size: 18))
                        .foregroundStyle(isSelected ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.capyBlue)
                                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                                    .matchedGeometryEffect(id: namespaceId, in: namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selection)
    }
}

private struct CapyShopSheet: View {
    let dayLabel: String
    let balance: Int
    let freezeCount: Int
    let freezeCost: Int
    let items: [CapyShopItem]
    let isPurchased: (CapyShopItem) -> Bool
    let onBuy: (CapyShopItem) -> Void
    let onBuyFreeze: () -> Bool
    let onReset: () -> Void
    let onUnlockAll: () -> Void
    let onRefillStats: () -> Void
    let onClearFreezes: () -> Void
    
    @State private var purchasedItem: CapyShopItem? = nil
    @State private var showSunburst = false
    @State private var flyingStats: [FlyingStat] = []
    
    @State private var centerPoint: CGPoint = .zero
    
    var body: some View {
        ZStack {
            mainContent
            celebrationOverlay
            flyingStatsLayer
        }
        .ignoresSafeArea()
    }
        
    private var mainContent: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 6)
                .padding(.top, 8)
            
            HStack {
                Text("capy shop")
                    .font(.custom("Gaegu-Regular", size: 28))
                    .foregroundStyle(Color.capyDarkBrown)
                Spacer()
                
//                HStack(spacing: 3) {
//                    Image(systemName: "snowflake")
//                        .font(.system(size: 12, weight: .bold))
//                    Text("x\(freezeCount)")
//                        .font(.custom("Gaegu-Regular", size: 18))
//                }
//                .foregroundStyle(Color.capyDarkBrown)
//                .padding(.horizontal, 8)
//                .padding(.vertical, 6)
//                .background(.white.opacity(0.92))
//                .clipShape(Capsule())
                
                Text("🪙")
                    .font(.custom("Gaegu-Regular", size: 20))
                    .padding(.top, 2)
                Text(String(balance))
                    .font(.custom("Gaegu-Regular", size: 26))
                    .foregroundStyle(Color.capyDarkBrown)
                    .contentTransition(.numericText(value: Double(balance)))
                    .animation(.snappy, value: balance)
            }
            .padding(.horizontal, 20)
            
//            Text("care drop for your capy: \(dayLabel)")
//                .font(.custom("Gaegu-Regular", size: 17))
//                .foregroundStyle(Color.capyBrown.opacity(0.75))
//                .padding(.horizontal, 20)
//                .padding(.top, 12)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    freezeShopSection
                        .padding(.vertical, 12)

                    ForEach(items) { item in
                        shopItemRow(item)
                    }
                    
                    Text("new items appear daily at midnight.")
                        .font(.custom("Gaegu-Regular", size: 18))
                        .foregroundStyle(Color.capyBrown.opacity(0.75))
                        .padding(.vertical, 14)
                    
                    VStack(spacing: 8) {
                        Button {
                            onReset()
                        } label: {
                            Text("[DEBUG: RESET SHOP & +100 COINS]")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.gray.opacity(0.5))
                        }
                        
                        Button {
                            onRefillStats()
                        } label: {
                            Text("[DEBUG: REFILL ALL STATS]")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.green.opacity(0.6))
                        }
                        
                        Button {
                            onUnlockAll()
                        } label: {
                            Text("[DEBUG: UNLOCK ALL DECORATIONS]")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.red.opacity(0.6))
                        }
                        
                        Button {
                            onClearFreezes()
                        } label: {
                            Text("[DEBUG: REMOVE ALL FREEZES]")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.blue.opacity(0.6))
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
        }
        //        .background(Color.capyBeige.opacity(0.96))
        .background(
            GeometryReader { geo in
                Color.capyBeige.opacity(0.96)
                    .onAppear {
                        centerPoint = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    }
            }
        )
    }

    private var freezeShopSection: some View {
        VStack(alignment: .leading, spacing: 8) {
//            Text("freeze protectors (always available)")
//                .font(.custom("Gaegu-Regular", size: 18))
//                .foregroundStyle(Color.capyBrown.opacity(0.9))

            HStack(spacing: 12) {
                Text("❄️")
                    .font(.system(size: 30))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Freeze Protector")
                        .font(.custom("Gaegu-Regular", size: 22))
                        .foregroundStyle(Color.capyDarkBrown)
                    Text("streak safety stock: \(freezeCount)/2")
                        .font(.custom("Gaegu-Regular", size: 16))
                        .foregroundStyle(Color.capyBrown.opacity(0.85))
                }

                Spacer()
                
                let isMaxed = freezeCount >= 2

                Button {
                    if !isMaxed {
                        if onBuyFreeze() {
                            let visualItem = CapyShopItem(
                                id: "freeze_protector",
                                emoji: "❄️",
                                title: "Freeze Protector",
                                description: "",
                                cost: freezeCost,
                                statReward: "❄️"
                            )
                            startCelebration(for: visualItem)
                        }
                    } else {
                        _ = onBuyFreeze()
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isMaxed {
                            Text("MAX")
                                .font(.custom("Gaegu-Regular", size: 20))
                        } else {
                            Text("🪙")
                                .font(.custom("Gaegu-Regular", size: 12))
                            Text(String(freezeCost))
                                .font(.custom("Gaegu-Regular", size: 20))
                        }
                    }
                    .foregroundStyle(isMaxed ? Color.capyBrown.opacity(0.5) : Color.capyBrown)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Capsule())
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private func shopItemRow(_ item: CapyShopItem) -> some View {
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
//                  Text(effectText(for: item))
//                      .font(.custom("Gaegu-Regular", size: 15))
//                      .foregroundStyle(Color.capyDarkBrown.opacity(0.78))
            }
            
            Spacer()
            
            let purchased = isPurchased(item)
            Button {
//                  onBuy(item)
                handleBuy(item)
            } label: {
                HStack(spacing: purchased ? 0 : 6) {
//                    Text(purchased ? "bought" : "")
//                        .font(.custom("Gaegu-Regular", size: 18))
                    
//                    HStack(spacing: purchased ? 0 : 2) {
//                        Text(purchased ? "" : "(")
//                            .font(.custom("Gaegu-Regular", size: 16))
                        
                        Text(purchased ? "" : "🪙")
                            .font(.custom("Gaegu-Regular", size: 12))
                        
                        Text(purchased ? "bought" : String(item.cost))
                            .font(.custom("Gaegu-Regular", size: 20))
                        
//                        Text(purchased ? "" : ")")
//                            .font(.custom("Gaegu-Regular", size: 16))
                        

//                    }
                }
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
    
    
    
    @ViewBuilder
    private var celebrationOverlay: some View {
        if let item = purchasedItem {
            Color.white.opacity(0.6)
                .ignoresSafeArea()
//                    .transition(.opacity)
                .onTapGesture {
                    closeCelebration()
                }
                .overlay {
                    ZStack {
//                    Image(systemName: "sun.max.fill")
                        Image("sunburst")
                            .resizable()
//                        .foregroundStyle(Color.white.opacity(0.3))
                            .opacity(0.8)
                            .frame(width: 600, height: 600)
                            .rotationEffect(.degrees(showSunburst ? 360 : 0))
                            .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: showSunburst)
                        
//                            Image(systemName: "sparkles")
//                            Image("sparkles")
//                                .resizable()
//                                .foregroundStyle(Color.yellow)
//                                .frame(width: 250, height: 250)
//                                .opacity(showSunburst ? 0.8 : 0)
//                                .scaleEffect(showSunburst ? 1.2 : 0.8)
//                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: showSunburst)
                        
                        Text(item.emoji)
                            .font(.system(size: 120))
                            .shadow(color: .white.opacity(0.5), radius: 20, x: 0, y: 10)
                            .scaleEffect(showSunburst ? 1.0 : 0.1)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showSunburst)
                    }
                }
                .zIndex(100)
                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
        }
    }
    
    private var flyingStatsLayer: some View {
        ForEach(flyingStats) { stat in
            Text(stat.emoji)
                .font(.system(size: 32))
                .modifier(FlyingStatModifier(stat: stat) {
                    flyingStats.removeAll(where: { $0.id == stat.id })
                })
                .zIndex(101)
        }
    }
    
    private func handleBuy(_ item: CapyShopItem) {
        onBuy(item)
        
        if isPurchased(item) {
            startCelebration(for: item)
        }
    }
        
    private func startCelebration(for item: CapyShopItem) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation {
            purchasedItem = item
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showSunburst = true
        }
        
        if let statReward = item.statReward {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                spawnFlyingStats(emoji: statReward)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            closeCelebration()
        }
    }
    
    private func closeCelebration() {
        withAnimation(.easeOut(duration: 0.6)) {
            purchasedItem = nil
//            showSunburst = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showSunburst = false
        }
    }
    
    private func spawnFlyingStats(emoji: String) {
        for i in 0..<6 {
            let randomXOffset = CGFloat.random(in: -60...60)
//            let randomYOffset = CGFloat.random(in: -20...20)
            
            let stat = FlyingStat(
                emoji: emoji,
                startPoint: centerPoint,
                endPoint: CGPoint(x: centerPoint.x + randomXOffset * 2, y: -100)
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                flyingStats.append(stat)
            }
        }
    }
    
//    private func effectText(for item: CapyShopItem) -> String {
//        guard let stat = item.statReward else {
//            return "effect: cosmetic only (no stat boost)"
//        }
//        switch stat {
//        case "🍋":
//            return "effect: +1 energy (🍋)"
//        case "🛁":
//            return "effect: +1 hygiene (🛁)"
//        case "😁":
//            return "effect: +1 mood (😁)"
//        default:
//            return "effect: +1 stat (\(stat))"
//        }
//    }
    
    private func effectText2(for item: CapyShopItem) -> String {
        guard let stat = item.statReward else { return "" }
        return "(+\(stat))"
    }
}

private struct ChallengeSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var store: CapyStore
    @Binding var challenge: CapyChallengeState

//    private var challenge: CapyChallengeState { store.challenge }
    let balance: Int
    let onStart: (CapyChallengeLength) -> Void
    
    private var layoutColumns: [GridItem] {
        let itemsPerRow: Int
        
        if challenge.length.rawValue == 30 {
            itemsPerRow = 10
        } else {
            itemsPerRow = 7
        }
        
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: itemsPerRow)
    }

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 6)
                .padding(.top, 10)
            
            HStack {
                VStack(spacing: 4) {
                    Text("challenge mode")
                        .font(.custom("Gaegu-Regular", size: 32))
                        .foregroundStyle(Color.capyDarkBrown)
                    Text("keep the streak alive!")
                        .font(.custom("Gaegu-Regular", size: 16))
                        .foregroundStyle(Color.capyBrown)
                }
//                Spacer()
//                HStack(spacing: 6) {
//                    Text("🪙")
//                    Text("\(balance)")
//                        .font(.custom("Gaegu-Regular", size: 24))
//                        .foregroundStyle(Color.capyBrown)
//                }
//                .padding(.bottom, 16)
//                .background(Color.white.opacity(0.5))
//                .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)

            if challenge.isActive {
                activeChallengeView
            } else {
                selectionView
            }
        }
        .padding(.bottom, 20)
        .background(Color.capyBeige.opacity(0.98))
    }
    
    private var activeChallengeView: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(challenge.length.title)
                        .font(.custom("Gaegu-Regular", size: 28))
                        .foregroundStyle(Color.capyDarkBrown)
                    
                    Text("\(challenge.completedCheckIns) of \(challenge.length.rawValue) days complete")
                        .font(.custom("Gaegu-Regular", size: 20))
                        .foregroundStyle(Color.capyBrown)
                }
                
                LazyVGrid(columns: layoutColumns, spacing: 12) {
                    ForEach(1...challenge.length.rawValue, id: \.self) { day in
                        dayCircle(day: day)
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 24)
                
                HStack(spacing: 30) {
                    VStack(spacing: 2) {
                        Text("reward")
                            .font(.custom("Gaegu-Regular", size: 16))
                            .foregroundStyle(Color.capyBrown)
                        Text("+\(challenge.length.completionBonusCoins)")
                            .font(.custom("Gaegu-Regular", size: 28))
                    }
                    
                    VStack(spacing: 2) {
                        Text("risk")
                            .font(.custom("Gaegu-Regular", size: 16))
                            .foregroundStyle(Color.capyBrown)
                        Text("-\(challenge.length.missPenaltyCoins)")
                            .font(.custom("Gaegu-Regular", size: 28))
                            .foregroundStyle(Color.red.opacity(0.8))
                    }
                }
                
//                VStack(spacing: 10) {
//                    Text("--- DEBUG ZONE ---")
//                        .font(.system(size: 10, weight: .bold))
//                        .foregroundStyle(.gray)
//                    
//                    HStack {
//                        Button("Simulate Next Day") {
//                            print("Button Tapped: Simulate Next Day")
//                            store.debugSimulateNextDay()
//                        }
//                        .font(.caption)
//                        .padding(8)
//                        .background(Color.blue.opacity(0.2))
//                        .cornerRadius(8)
//                        
//                        Button("+1 Check In") {
//                            print("Button Tapped: +1 Check In")
//                            store.debugSimulateNextDay()
//                        }
//                        .font(.caption)
//                        .padding(8)
//                        .background(Color.blue.opacity(0.2))
//                        .cornerRadius(8)
//                    }
//                    
//                    Button("Force Fail / Reset") {
//                        store.stopChallenge(completed: false)
//                    }
//                    .font(.caption)
//                    .padding(8)
//                    .background(Color.red.opacity(0.2))
//                    .cornerRadius(8)
//                }
//                .padding(.top, 20)
            }
        }
    }
    
    @ViewBuilder
    private func dayCircle(day: Int) -> some View {
        let isCompleted = day <= challenge.completedCheckIns
        let isDoneForToday = Calendar.current.isDateInToday(challenge.lastCheckInDate ?? .distantPast)
        let todayIndex = challenge.completedCheckIns + (isDoneForToday ? 0 : 1)
        
        let isToday = (day == todayIndex)
        
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.05))
            Text("🔥")
                .font(.system(size: 18))
                .saturation(isCompleted ? 1 : 0)
                .opacity(isCompleted ? 1 : 0.6)
            if isToday {
                Circle()
                    .strokeBorder(Color.capyDarkBrown, lineWidth: 2)
                    .opacity(0.8)
            }
        }
        .frame(height: 44)
    }
    
    private var selectionView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                Text("pick your goal")
                    .font(.custom("Gaegu-Regular", size: 20))
                    .foregroundStyle(Color.capyBrown.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                
                ForEach(CapyChallengeLength.allCases) { length in
                    Button {
                        onStart(length)
                        dismiss()
                    } label : {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(length.title)
                                    .font(.custom("Gaegu-Regular", size: 26))
                                    .foregroundStyle(Color.capyDarkBrown)
                                Text("\(length.rawValue) days streak")
                                    .font(.custom("Gaegu-Regular", size: 16))
                                    .foregroundStyle(Color.capyBrown)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("+\(length.completionBonusCoins) coins")
                                    .font(.custom("Gaegu-Regular", size: 22))
                                    .foregroundStyle(Color.capyBlue)
                                Text("miss: -\(length.missPenaltyCoins)")
                                    .font(.custom("Gaegu-Regular", size: 16))
                                    .foregroundStyle(Color.red.opacity(0.7))
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 4)
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer().frame(height: 20)
            }
        }
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

struct FlyingStat: Identifiable {
    let id = UUID()
    var emoji: String
    var startPoint: CGPoint
    var endPoint: CGPoint
}

struct FlyingStatModifier: ViewModifier {
    let stat: FlyingStat
    let onComplete: () -> Void
    
    @State private var progress: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .position(
                x: stat.startPoint.x + (stat.endPoint.x - stat.startPoint.x) * progress,
                y: stat.startPoint.y + (stat.endPoint.y - stat.startPoint.y) * progress
            )
            .opacity(1.0 - progress)
            .scaleEffect(1.0 - (progress * 0.5))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    progress = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    onComplete()
                }
            }
    }
}

struct ReviewSheet: View {
    @ObservedObject var store: CapyStore
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 6)
                .padding(.top, 16)
            
            Text("career stats")
                .font(.custom("Gaegu-Regular", size: 32))
                .foregroundStyle(Color.capyDarkBrown)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            
            ScrollView {
                VStack(spacing: 24) {
                    LazyVGrid(columns: columns, spacing: 8) {
                        statCard(
                            emoji: "🏆",
                            title: "Level \(store.progressionLevel)",
                            subtitle: store.progressionTitle,
                            color: .capyBlue
                        )
                        statCard(
                            emoji: "🔥",
                            title: "\(store.stats.streak) Day",
                            subtitle: "current streak",
                            color: .orange
                        )
                        statCard(
                            emoji: "✅",
                            title: "\(store.stats.totalCompletions)",
                            subtitle: "total tasks done",
                            color: .green
                        )
                        statCard(
                            emoji: "⚡",
                            title: "\(store.stats.xp) XP",
                            subtitle: "lifetime XP",
                            color: .purple
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack{
                            Text("progress to next lvl")
                                .font(.custom("Gaegu-Regular", size: 18))
                                .foregroundStyle(Color.capyBrown)
                            Spacer()
                            Text("\(store.xpIntoCurrentLevel) / \(store.xpNeededForNextLevel) XP")
                                .font(.custom("Gaegu-Regular", size: 16))
                                .foregroundStyle(Color.capyBrown.opacity(0.7))
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.black.opacity(0.05))
                                    .frame(height: 12)
                                
                                Capsule()
                                    .fill(Color.capyBlue)
                                    .frame(width: geo.size.width * store.progressionToNextLevel, height: 12)
                            }
                        }
                        .frame(height: 12)
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 24)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("unlocked perks")
                            .font(Font.custom("Gaegu-Regular", size: 24))
                            .foregroundStyle(Color.capyDarkBrown)
                            .padding(.horizontal, 4)
                        
                        ForEach(store.unlockedProgressionPerks, id: \.self) { perk in
                            HStack(spacing: 12) {
                                Image(systemName: "lock.open.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.capyBlue)
                                Text(perk)
                                    .font(.custom("Gaegu-Regular", size: 18))
                                    .foregroundStyle(Color.capyBrown)
                                Spacer()
                            }
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .background(Color.capyBeige.opacity(0.98))
    }
    
    @ViewBuilder
    private func statCard(emoji: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 32))
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.custom("Gaegu-Regular", size: 22))
                    .foregroundStyle(Color.capyDarkBrown)
                
                Text(subtitle)
                    .font(.custom("Gaegu-Regular", size: 14))
                    .foregroundStyle(Color.capyBrown.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 4)
    }
}

#Preview {
    HomeView2(store: CapyStore())
}
