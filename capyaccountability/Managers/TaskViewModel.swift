//
//  TaskViewModel.swift
//  capyaccountability
//
//  Created by Hodan on 05.02.2026.
//

import SwiftUI
import Combine

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    
    func generateTasks(from aiGoals: UserGoals) {
        var newTasks: [TaskItem] = []
        
        func add(_ text: String, _ time: Timeframe, _ coins: Int, _ reward: String) {
            newTasks.append(TaskItem(text: text, isDone: false, timeframe: time, coinReward: coins, statReward: reward))
        }
        
        for goal in aiGoals.daily { add(goal, .daily, 10, "😁") }
        for goal in aiGoals.weekly { add(goal, .week, 30, "🍋") }
        for goal in aiGoals.monthly { add(goal, .month, 50, "🛁") }
        for goal in aiGoals.yearly { add(goal, .year, 100, "😁") }
        for goal in aiGoals.decade { add(goal, .decade, 500, "🍋") }
        for goal in aiGoals.longTerm { add(goal, .allTime, 1000, "🛁") }
        
        DispatchQueue.main.async {
            withAnimation {
                self.tasks.append(contentsOf: newTasks)
            }
        }
    }
}
