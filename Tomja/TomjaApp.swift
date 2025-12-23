//
//  TomjaApp.swift
//  Tomja
//
//  Created by Tom Knighton on 21/12/2025.
//

import SwiftUI
import API
import SwiftData
import UserNotifications

@main
struct TomjaApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var api = APIClient(host: "https://api.labels.tomk.online/")
    @State private var pushManager = PushRegistrationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.networkClient, api)
                .modelContainer(for: [LocalUser.self, LocalHome.self])
                .environment(pushManager)
                .onAppear {
                    appDelegate.pushManager = pushManager
                    appDelegate.api = api
                }
        }
    }
}

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var pushManager: PushRegistrationManager?
    var api: (any NetworkClient)?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { @MainActor in
            pushManager?.didReceiveDeviceToken(token, api: api)
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            pushManager?.didFailToRegister(error)
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        NotificationCenter.default.post(name: .deviceUpdated, object: nil)
        let name = notification.request.content.title
        
        if name.hasSuffix("Failed") {
            if name.hasPrefix("Flash") {
                NotificationCenter.default.post(name: .deviceFailFlash, object: nil)
            }
            
            if name.hasPrefix("Clear") {
                NotificationCenter.default.post(name: .deviceFailClear, object: nil)
            }
            
            if name.hasPrefix("Image") {
                NotificationCenter.default.post(name: .deviceFailImage, object: nil)
            }
        }
        
        completionHandler([])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        NotificationCenter.default.post(name: .deviceUpdated, object: nil)
        completionHandler()
    }
}
