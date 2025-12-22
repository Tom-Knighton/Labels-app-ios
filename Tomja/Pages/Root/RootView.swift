//
//  RootView.swift
//  Tomja
//
//  Created by Tom Knighton on 22/12/2025.
//

import SwiftUI
import SwiftData
import AppRouter

public struct RootView: View {
    
    @Environment(\.home) private var home
    @Environment(\.user) private var user
    @State private var router = AppRouter(initialTab: .home)
    @State var selection: AppTab = AppTab.home

        
    public var body: some View {
        TabView(selection: $selection) {
            Tab(value: AppTab.home) {
                NavigationStack(path: $router[.home]) {
                    HomePage()
//                        .environment(\.home, home)
//                        .environment(\.user, user)
                }
                
            } label: {
                Label(AppTab.home.title, systemImage: AppTab.home.icon)
            }
        }
        .environment(router)
    }
}
