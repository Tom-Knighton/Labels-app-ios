//
//  RootView.swift
//  Tomja
//
//  Created by Tom Knighton on 22/12/2025.
//

import SwiftUI
import SwiftData
import AppRouter
import UserNotifications

public struct RootView: View {
    
    @Environment(\.networkClient) private var api
    @Environment(\.home) private var home
    @Environment(\.user) private var user
    @Environment(PushRegistrationManager.self) private var pushManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var router = AppRouter(initialTab: .home)
    @State var selection: AppTab = AppTab.home    
        
    public var body: some View {
        TabView(selection: $selection) {
            Tab(value: AppTab.home) {
                NavigationStack(path: $router[.home]) {
                    HomePage()
                }
            } label: {
                Label(AppTab.home.title, systemImage: AppTab.home.icon)
            }
            
            Tab(value: AppTab.profile) {
                NavigationStack(path: $router[.profile]) {
                    ProfilePage()
                }
            } label: {
                Label(AppTab.profile.title, systemImage: AppTab.profile.icon)
            }
        }
        .environment(router)
        .onAppear {
            self.pushManager.refreshAndRegisterIfNeeded(api: api)
            self.pushManager.requestPermission(api: api)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                pushManager.refreshAndRegisterIfNeeded(api: api)
            }
        }
    }
}

@MainActor
func requestNotificationPermission() async -> Bool {
    let center = UNUserNotificationCenter.current()
    
    let settings = await center.notificationSettings()
    switch settings.authorizationStatus {
    case .authorized, .provisional, .ephemeral:
        return true
        
    case .notDetermined:
        do {
            return try await center.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
        } catch {
            return false
        }
        
    case .denied:
        return false
        
    @unknown default:
        return false
    }
}

