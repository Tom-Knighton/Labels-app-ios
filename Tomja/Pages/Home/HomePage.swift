//
//  HomePage.swift
//  Tomja
//
//  Created by Tom Knighton on 22/12/2025.
//

import SwiftUI
import API

public struct HomePage: View {
    
    @Environment(\.home) private var home
    @Environment(\.user) private var user
    @Environment(\.networkClient) private var api
    
    @State private var currentHome: HomeDTO? = nil
    @State private var loadTask: Task<Void, Never>?
    
    public var body: some View {
        ZStack {
            Color.color1.ignoresSafeArea()
            
            if let currentHome {
                if currentHome.users.isEmpty {
                    ContentUnavailableView("Something went wrong", systemImage: "exclamationmark.triangle", description: Text("We were unable to retrieve any users"))
                }
                usersList(for: currentHome)
                    .navigationTitle(home.name)
            } else {
                ProgressView()
            }
        }
        .task {
            await load()
        }
        .refreshable {
            await load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .deviceUpdated), perform: { _ in
            Task { await load() }
        })
        .fontDesign(.rounded)
    }
}

extension HomePage {
    
    @ViewBuilder
    func usersList(for home: HomeDTO) -> some View {
        ScrollView {
            ForEach(home.users) { user in
                UserHomeRowView(user: user)
            }
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
    }
    
    private func load() async {
        loadTask?.cancel()
        
        loadTask = Task {
            do {
                self.currentHome = try await api.get(Homes.my)
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomePage()
            .environment(\.home, LocalHome(id: "1", name: "Tom's Home", joinCode: "XXXXXX", isPrivate: true))
            .environment(\.user, LocalUser(id: "2", name: "Tom", homeId: "1"))
            .environment(\.networkClient, MockClient())
    }
}
