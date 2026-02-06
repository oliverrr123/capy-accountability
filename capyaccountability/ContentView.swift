//
//  ContentView.swift
//  capyaccountability
//
//  Created by Yazide Arsalan on 29/1/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("capy_has_onboarded") private var hasOnboarded = true
//    @AppStorage("capy_user_name") private var userName = ""
//    @AppStorage("capy_user_goals") private var userGoals = ""
    
//    @StateObject var taskViewModel = TaskViewModel()
    @StateObject private var store = CapyStore()

    var body: some View {
        if hasOnboarded {
//            HomeView(name: userName, goals: userGoals)
            HomeView2(store: store)
        } else {
            OnboardingFlowView(
                onFinish: { name, _ in
//                    userName = name
//                    userGoals = goals
                    
                    store.updateProfile(name: name, goalsText: "")
                    withAnimation {
                        hasOnboarded = true
                    }
                },
                store: store
            )
        }
    }
}

#Preview {
    ContentView()
}
