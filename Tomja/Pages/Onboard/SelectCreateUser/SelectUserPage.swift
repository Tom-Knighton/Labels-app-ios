//
//  SelectUserPage.swift
//  Tomja
//
//  Created by Tom Knighton on 21/12/2025.
//

import SwiftUI
import SwiftData
import API

public struct SelectUserPage: View {
    
    @Environment(\.networkClient) private var api
    @Environment(\.modelContext) private var context
    
    @Environment(\.home) private var home
    
    @State private var users: [UserDTO] = []
    @State private var isLoading: Bool = false
    @State private var selectedId: String? = nil
    
    public var body: some View {
        ZStack {
            Color.color1.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
            }
            
            ScrollView {
                Text("Select a user or create a new one!")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .font(.subheadline)
                Spacer().frame(height: 32)
                ForEach(users) { user in
                    HStack {
                        ZStack {
                            Circle()
                                .fill(selectedId == user.id ? Color.accentColor : Color.color1)
                                .frame(width: 30, height: 30)
                                .shadow(radius: 1)
                            
                            if selectedId == user.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.white)
                                    .bold()
                                    .transition(.symbolEffect)
                            } else {
                                Text(user.name.prefix(1))
                                    .fontWeight(.bold)
                            }
                        }
                        Text(user.name)
                        Spacer()
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.color2)
                    .cornerRadius(10)
                    .shadow(radius: 3)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .onTapGesture {
                        self.selectedId = user.id
                    }
                }
                
                Spacer().frame(minHeight: 128)
                Button(action: { Task { await self.selectUser(selectedId ?? "")}}) {
                    Text("Select")
                        .padding(.vertical, 4)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
                .buttonPlatformProminent()
                .disabled(self.selectedId == nil)
                
                HStack {
                    Rectangle().frame(height: 0.3)
                    Text("Or")
                    Rectangle().frame(height: 0.3)
                }
                
                NavigationLink {
                    CreateUserPage()
                        .environment(\.home, home)
                } label: {
                    Text("Create new User")
                        .padding(.vertical, 4)
                        .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                }
                .buttonPlatformBordered()
            }
            .navigationTitle(home.name)
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .scrollBounceBehavior(.basedOnSize)
            .sensoryFeedback(.selection, trigger: self.selectedId)
        }
        .fontDesign(.rounded)
        .task(id: home.id) {
            self.isLoading = true
            defer { self.isLoading = false }
                        
            do {
                let users: [UserDTO] = try await api.get(Users.getForHome(homeId: home.id, code: home.joinCode))
                self.users = users
            } catch {
                print(error)
            }
        }
    }
}

extension SelectUserPage {
    
    func selectUser(_ userId: String) async {
        self.isLoading = true
        defer { self.isLoading = false }
        
        do {
            let user: UserDTO? = try await api.post(Users.authAs(userId: userId, code: home.joinCode))
            if let user, let key = user.apiKey {
                try context.delete(model: LocalUser.self)
                context.insert(LocalUser(id: user.id, name: user.name, homeId: user.homeId))
                try context.save()
                _ = KeychainStore.setAPIKey(key)
            }
        } catch {
            print(error)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: LocalHome.self, LocalUser.self, configurations: config)
    
    return NavigationStack {
        SelectUserPage()
            .environment(\.networkClient, MockClient())
            .environment(\.home, LocalHome(id: "111", name: "Mock Home", joinCode: "XXXXXX", isPrivate: true))
    }
    .modelContainer(container)
}
