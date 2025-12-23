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
    
    @State private var error: String? = nil
    private var alertIsPresented: Binding<Bool> {
        Binding(
            get: { error != nil },
            set: { isPresented in
                if !isPresented {
                    error = nil
                }
            }
        )
    }
        
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
        .alert("Uh oh!", isPresented: alertIsPresented, actions: {
            Button(action: { self.error = nil }) { Text("Ok") }
        }, message:  {
            Text(error ?? "")
        })
        .onReceive(NotificationCenter.default.publisher(for: .deviceFailClear)) { _ in
            self.error = "Your last request to clear a device failed - please try again. This is likely a temporary connection issue!"
        }
        .onReceive(NotificationCenter.default.publisher(for: .deviceFailFlash)) { _ in
            self.error = "Your last request to flash a device failed - please try again. This is likely a temporary connection issue!"
        }
        .onReceive(NotificationCenter.default.publisher(for: .deviceFailImage)) { _ in
            self.error = "Your last request to set a device's image failed - please try again. This is likely a temporary connection issue!"
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

