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

    var body: some View {
        if hasOnboarded {
            HomeView(name: userName, goals: userGoals)
        } else {
            OnboardingFlowView { name, goals in
                userName = name
                userGoals = goals
                hasOnboarded = true
            }
        }
    }
}

#Preview {
    ContentView()
}
