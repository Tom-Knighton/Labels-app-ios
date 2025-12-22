//
//  RootView.swift
//  Tomja
//
//  Created by Tom Knighton on 22/12/2025.
//

import SwiftUI
import SwiftData

public struct RootView: View {
    
    @Environment(\.modelContext) private var context
    @Environment(\.user) private var user
    @Environment(\.home) private var home
        
    public var body: some View {
        Text("Hello World \(user.name) - \(home.name)")
        Button(action: { Task {
            try? context.delete(model: LocalUser.self)
            try? context.delete(model: LocalHome.self)
            try? context.save()
        }} ) { Text("Logout") }
            .buttonPlatformBordered()
    }
}
