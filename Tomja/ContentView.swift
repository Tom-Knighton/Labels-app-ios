//
//  ContentView.swift
//  Tomja
//
//  Created by Tom Knighton on 21/12/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var homes: [LocalHome]
    @Query private var users: [LocalUser]
    
    @Environment(\.modelContext) private var context
    
    var body: some View {
        ZStack {
            if let home = homes.first {
                if let user = users.first {
                    RootView()
                        .environment(\.user, user)
                        .environment(\.home, home)
                } else {
                    NavigationStack {
                        SelectUserPage()
                            .environment(\.home, home)
                    }
                }
            } else {
                LandingPage()
            }
        }
    }
}

#Preview {
    ContentView()
}
