//
//  PushRegistrationManager.swift
//  Tomja
//
//  Created by Tom Knighton on 23/12/2025.
//


import Foundation
import UserNotifications
import UIKit
import API

@MainActor
@Observable
final class PushRegistrationManager {
    enum AuthState: String, Codable {
        case notDetermined, denied, authorized, provisional, ephemeral, unknown
    }

    private let defaults = UserDefaults.standard
    private let lastSentTokenKey = "push.lastSentToken"
    private let lastSentAuthKey = "push.lastSentAuth"

    private(set) var authState: AuthState = .unknown

    func refreshAndRegisterIfNeeded(api: any NetworkClient) {
        Task {
            let state = await currentAuthState()
            authState = state

            print("APNS: \(state) vs \(lastSentAuthState())")
            if state != lastSentAuthState() {
                await sendToApiIfNeeded(token: nil, authState: state, api: api)
            }

            if state == .authorized || state == .provisional || state == .ephemeral {
                await registerForRemoteNotifications()
            }
        }
    }
    
    func requestPermission(api: any NetworkClient) {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            
            switch settings.authorizationStatus {
            case .notDetermined:
                do {
                    let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                    
                    let state = await currentAuthState()
                    authState = state
                    await sendToApiIfNeeded(token: nil, authState: state, api: api)
                    
                    if granted {
                        await registerForRemoteNotifications()
                    }
                } catch {
                }
                
            case .authorized, .provisional, .ephemeral:
                let state = await currentAuthState()
                authState = state
                await sendToApiIfNeeded(token: nil, authState: state, api: api)
                await registerForRemoteNotifications()
                
            case .denied:
                let state = await currentAuthState()
                authState = state
                await sendToApiIfNeeded(token: nil, authState: state, api: api)
                
            @unknown default:
                break
            }
        }
    }

    func didReceiveDeviceToken(_ token: String, api: (any NetworkClient)?) {
        Task {
            let state = await currentAuthState()
            authState = state
            await sendToApiIfNeeded(token: token, authState: state, api: api)
        }
    }

    func didFailToRegister(_ error: Error) {
    }

    // MARK: - Internals

    private func currentAuthState() async -> AuthState {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .authorized
        case .provisional: return .provisional
        case .ephemeral: return .ephemeral
        @unknown default: return .unknown
        }
    }

    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    private func lastSentAuthState() -> AuthState {
        guard let raw = defaults.string(forKey: lastSentAuthKey),
              let state = AuthState(rawValue: raw) else { return .unknown }
        return state
    }

    private func lastSentToken() -> String? {
        defaults.string(forKey: lastSentTokenKey)
    }

    private func setLastSent(authState: AuthState, token: String?) {
        defaults.set(authState.rawValue, forKey: lastSentAuthKey)
        if let token {
            defaults.set(token, forKey: lastSentTokenKey)
        }
    }

    private func sendToApiIfNeeded(token: String?, authState: AuthState, api: (any NetworkClient)?) async {
        let authChanged = authState != lastSentAuthState()
        let tokenChanged = (token != nil && token != lastSentToken())

        guard let api, authChanged || tokenChanged else { return }

        do {
            let success: String = try await api.post(Users.registerApns(token: token ?? "", name: UIDevice.current.name))
            setLastSent(authState: authState, token: token)
        } catch {
        }
    }
}
