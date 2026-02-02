//
//  ContentView.swift
//  Capy Accountability
//
//  Created by Hodan on 01.02.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Text("Capy").font(.custom("CherryBombOne-Regular", size: 96)).foregroundStyle(.white)
            Text("Accountability").font(.custom("CherryBombOne-Regular", size: 32)).foregroundStyle(.white)
            
            Spacer()
            
            Image("Capy")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .saturation(/*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 28/255, green: 149/255, blue: 255/255))
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
