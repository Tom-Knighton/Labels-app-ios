//
//  TomjaApp.swift
//  Tomja
//
//  Created by Tom Knighton on 21/12/2025.
//

import SwiftUI
import API
import SwiftData

@main
struct TomjaApp: App {
    
    @State private var api = APIClient(host: "https://api.dev.labels.tomk.online/")
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.networkClient, api)
                .modelContainer(for: [LocalUser.self, LocalHome.self])
        }
    }
}
