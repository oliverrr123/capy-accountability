import AuthenticationServices
import AVFoundation
import AudioToolbox
import Combine
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
    let endPosition: CGPoint = CGPoint(x: 32, y: 87)
}

struct CapyShopItem: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let description: String
    let cost: Int
    let statReward: String?
}

enum Timeframe: String, CaseIterable {
    case daily = "Daily"
    case week = "This week"
    case month = "This month"
    case year = "This year"
    case decade = "This decade"
    case allTime = "All time"
}

struct HomeView2: View {
    @ObservedObject var viewModel: TaskViewModel

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var brain = CapyBrain()

    @AppStorage("capy_shop_last_day_key") private var shopLastDayKey = ""
    @AppStorage("capy_shop_purchased_ids") private var purchasedShopItemsCSV = ""
    @AppStorage("capy_last_goal_checkin_ts") private var lastGoalCheckInTimestamp = 0.0

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
    @State private var selectedTimeframe: Timeframe = .daily

    @State private var showShopSheet = false
    @State private var shopItems: [CapyShopItem] = []
    @State private var currentShopDayKey = ""
    @State private var showShopAlert = false
    @State private var shopAlertMessage = ""

    @State private var capyText = "hi, i'm capy. want to buy me a little care item and then do one tiny goal step?"
    @State private var capyInput = ""
    @State private var capyIsThinking = false
    @State private var lastSessionGoalCheckInDate = Date.distantPast

    private let goalCheckInTimer = Timer.publish(every: 50, on: .main, in: .common).autoconnect()

    private let shopCatalog: [CapyShopItem] = [
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

            GeometryReader { geometry in
                VStack(spacing: 10) {
                    topBar
                    shopCareHint
                    todoPart
                    capyPart(bottomInset: geometry.safeAreaInsets.bottom)
                }
                .padding(.top, geometry.safeAreaInsets.top + 6)
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, 12))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

            GeometryReader { _ in
                ForEach(flyingCoins) { coin in
                    Image("coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
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
        .alert("CapyShop", isPresented: $showShopAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(shopAlertMessage)
        }
        .sheet(isPresented: $showShopSheet) {
            CapyShopSheet(
                dayLabel: shopDayLabel(from: currentShopDayKey),
                balance: Int(balance),
                items: shopItems,
                isPurchased: { isPurchased($0) },
                onBuy: { buyShopItem($0) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            refreshDailyShopIfNeeded(force: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                maybeAskGoalCheckIn()
            }
        }
        .onReceive(goalCheckInTimer) { _ in
            maybeAskGoalCheckIn()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            refreshDailyShopIfNeeded()
            maybeAskGoalCheckIn()
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
        .padding(.horizontal, 20)
    }

    private var shopCareHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.system(size: 12, weight: .semibold))
            Text("buy care items for your capy to boost mood, energy, and hygiene")
                .font(.custom("Gaegu-Regular", size: 16))
        }
        .foregroundStyle(Color.capyDarkBrown.opacity(0.9))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.white.opacity(0.88))
        .clipShape(Capsule())
        .padding(.horizontal, 20)
    }

    private var todoPart: some View {
        VStack(spacing: 6) {
            timeframeSwitcher
                .zIndex(1)

            VStack(alignment: .leading) {
                let filteredTasks = viewModel.tasks.filter { $0.timeframe == selectedTimeframe }

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
                                if let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
                                    HStack {
                                        Image(viewModel.tasks[index].isDone ? "tick_done" : "tick_empty")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24)

                                        Text(viewModel.tasks[index].text)
                                            .font(.custom("Gaegu-Regular", size: 24))
                                            .strikethrough(task.isDone)
                                            .foregroundStyle(Color.capyDarkBrown)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .onTapGesture(coordinateSpace: .global) { location in
                                        toggleTask($viewModel.tasks[index], at: location)
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

    private func capyPart(bottomInset: CGFloat) -> some View {
        VStack(spacing: -6) {
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

                    if capyIsThinking {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(Color.capyDarkBrown)
                            Text("Capy is thinking...")
                                .font(.custom("Gaegu-Regular", size: 16))
                                .foregroundStyle(Color.capyDarkBrown.opacity(0.8))
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 42)
            }
            .padding(.horizontal, 20)

            HStack(spacing: 10) {
                TextField("reply to capy...", text: $capyInput)
                    .font(.custom("Gaegu-Regular", size: 20))
                    .foregroundStyle(Color.capyDarkBrown)
                    .submitLabel(.send)
                    .onSubmit(sendMessageToCapy)

                Button(action: sendMessageToCapy) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.capyBlue)
                        .clipShape(Circle())
                }
                .disabled(capyIsThinking)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.white.opacity(0.88))
            .clipShape(Capsule())
            .padding(.horizontal, 20)

            HStack(spacing: 10) {
                quickActionButton(title: "goal check-in", icon: "target") {
                    maybeAskGoalCheckIn(force: true)
                }
                capyAIButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)

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
                    .padding(.bottom, bottomInset + 10)
                }
        }
    }

    private func quickActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .font(.custom("Gaegu-Regular", size: 18))
            }
            .foregroundStyle(Color.capyDarkBrown)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.white.opacity(0.88))
            .clipShape(Capsule())
        }
    }

    private var capyAIButton: some View {
        Button(action: requestAINudge) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                Text("capyai")
                    .font(.custom("Gaegu-Regular", size: 18))
                Text("calm nudge")
                    .font(.custom("Gaegu-Regular", size: 16))
                    .foregroundStyle(Color.capyDarkBrown.opacity(0.65))
            }
            .foregroundStyle(Color.capyDarkBrown)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.white.opacity(0.88))
            .clipShape(Capsule())
        }
    }

    private var purchasedItemIDs: Set<String> {
        Set(purchasedShopItemsCSV.split(separator: ",").map(String.init))
    }

    private var pendingTasks: [TaskItem] {
        viewModel.tasks.filter { !$0.isDone }
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
            capyText = "Yuzu power-up. Nice work on \"\(task.wrappedValue.text)\". Want to push one more goal?"
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                maybeAskGoalCheckIn()
            }
        } else {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            withAnimation {
                balance -= Double(reward)
                if let emoji = statEmoji { updateStat(emoji: emoji, change: -1) }
            }
            capyText = "No stress. Let's take another swing at \"\(task.wrappedValue.text)\"."
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
        for _ in 0..<visualCoins {
            let randomX = Double.random(in: -10...10)
            let randomY = Double.random(in: -10...10)
            let offset = CGSize(width: randomX, height: randomY)

            let coin = FlyingCoin(
                startPosition: startPoint,
                explodeOffset: offset
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
            viewModel.tasks.append(newItem)
        }
    }

    private func deleteTask(_ item: TaskItem) {
        if let index = viewModel.tasks.firstIndex(where: { $0.id == item.id }) {
            _ = withAnimation {
                viewModel.tasks.remove(at: index)
            }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }

    private func saveTaskEdit(_ item: TaskItem, newText: String) {
        if let index = viewModel.tasks.firstIndex(where: { $0.id == item.id }) {
            viewModel.tasks[index].text = newText
        }
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
        let ranked = shopCatalog.sorted {
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
            shopAlertMessage = "You already bought \(item.title) today."
            showShopAlert = true
            return
        }

        guard balance >= Double(item.cost) else {
            shopAlertMessage = "Not enough coins for \(item.title)."
            showShopAlert = true
            return
        }

        withAnimation {
            balance -= Double(item.cost)
        }
        markPurchased(item.id)
        if let stat = item.statReward {
            updateStat(emoji: stat, change: 1)
        }

        capyText = "thank you. you got \(item.title.lowercased()) for your capy. want a gentle goal check-in now?"
        shopAlertMessage = "Purchased \(item.title) for your capy. capyshop refreshes with new care items tomorrow."
        showShopAlert = true
    }

    private func maybeAskGoalCheckIn(force: Bool = false) {
        guard !capyIsThinking else { return }
        guard let targetTask = pendingTasks.randomElement() else { return }

        let now = Date()
        let lastGlobalCheckIn = Date(timeIntervalSince1970: lastGoalCheckInTimestamp)
        let sessionCooldown: TimeInterval = 90
        let globalCooldown: TimeInterval = 15 * 60

        if !force {
            guard now.timeIntervalSince(lastSessionGoalCheckInDate) > sessionCooldown else { return }
            guard now.timeIntervalSince(lastGlobalCheckIn) > globalCooldown else { return }
        }

        let prompts = [
            "Quick goal check-in: how is \"{goal}\" going?",
            "Are you still on track for \"{goal}\" today?",
            "Want to take a 10-minute step toward \"{goal}\" right now?",
            "For \"{goal}\", what would make progress easy this hour?"
        ]

        let template = prompts.randomElement() ?? "How are you doing with \"{goal}\"?"
        capyText = template.replacingOccurrences(of: "{goal}", with: targetTask.text)
        lastSessionGoalCheckInDate = now
        lastGoalCheckInTimestamp = now.timeIntervalSince1970
    }

    private func requestAINudge() {
        guard !capyIsThinking else { return }
        let focusGoal = pendingTasks.randomElement()?.text ?? "staying consistent today"
        capyInput = ""
        capyIsThinking = true

        Task {
            let reply = await brain.coachReply(
                userMessage: "Give me one short accountability nudge for \(focusGoal). End with one question.",
                goals: pendingTasks.map { $0.text },
                completedCount: viewModel.tasks.filter { $0.isDone }.count,
                pendingCount: pendingTasks.count
            )
            await MainActor.run {
                capyText = reply
                capyIsThinking = false
            }
        }
    }

    private func sendMessageToCapy() {
        let message = capyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, !capyIsThinking else { return }

        capyInput = ""
        capyIsThinking = true

        Task {
            let reply = await brain.coachReply(
                userMessage: message,
                goals: pendingTasks.map { $0.text },
                completedCount: viewModel.tasks.filter { $0.isDone }.count,
                pendingCount: pendingTasks.count
            )
            await MainActor.run {
                capyText = reply
                capyIsThinking = false
            }
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
                VStack(alignment: .leading, spacing: 2) {
                    Text("capyshop")
                        .font(.custom("Gaegu-Regular", size: 32))
                    Text("care drop for your capy: \(dayLabel)")
                        .font(.custom("Gaegu-Regular", size: 17))
                        .foregroundStyle(Color.capyBrown.opacity(0.75))
                }
                Spacer()
                Text("🪙 \(balance)")
                    .font(.custom("Gaegu-Regular", size: 24))
            }
            .padding(.horizontal, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(items) { item in
                        HStack(spacing: 12) {
                            Text(item.emoji)
                                .font(.system(size: 30))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.custom("Gaegu-Regular", size: 22))
                                    .foregroundStyle(Color.capyDarkBrown)
                                Text(item.description)
                                    .font(.custom("Gaegu-Regular", size: 16))
                                    .foregroundStyle(Color.capyBrown.opacity(0.78))
                            }

                            Spacer()

                            let purchased = isPurchased(item)
                            Button {
                                onBuy(item)
                            } label: {
                                Text(purchased ? "equipped" : "\(item.cost)")
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
                }
                .padding(.horizontal, 20)
            }

            Text("new capy care items appear daily at midnight.")
                .font(.custom("Gaegu-Regular", size: 18))
                .foregroundStyle(Color.capyBrown.opacity(0.75))
                .padding(.bottom, 14)
        }
        .background(Color.capyBeige.opacity(0.96))
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
