//
//  ContentView.swift
//  Fast
//
//  Created by Zachary Terrell on 6/21/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            // stub for future History screen
            Text("History")
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
        }
    }
}

#Preview {
    ContentView()
}
