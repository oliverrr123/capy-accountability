//
//  ContentView.swift
//  capyaccountability
//
//  Created by Yazide Arsalan on 29/1/26.
//

import SwiftUI

struct ContentView: View {
    @State private var name = ""
    
    var body: some View {
        InitialView()
//        SpeechView2(name: $name) {
//            print("Name: ", name)
//            name = ""
//        }
    }
}

#Preview {
    ContentView()
}
