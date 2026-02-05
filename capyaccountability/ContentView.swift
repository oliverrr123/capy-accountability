//
//  ContentView.swift
//  capyaccountability
//
//  Created by Yazide Arsalan on 29/1/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("capy_has_onboarded") private var hasOnboarded = false
    @AppStorage("capy_user_name") private var userName = ""
    @AppStorage("capy_user_goals") private var userGoals = ""
    
    @StateObject var taskViewModel = TaskViewModel()

    var body: some View {
        if hasOnboarded {
//            HomeView(name: userName, goals: userGoals)
            HomeView2(viewModel: taskViewModel)
        } else {
            OnboardingFlowView(
                onFinish: { name, goals in
                    userName = name
                    userGoals = goals
                    
                    withAnimation {
                        hasOnboarded = true
                    }
                },
                taskViewModel: taskViewModel
            )
        }
    }
}

#Preview {
    ContentView()
}
