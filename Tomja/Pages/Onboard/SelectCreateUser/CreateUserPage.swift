//
//  CreateUserPage.swift
//  Tomja
//
//  Created by Tom Knighton on 21/12/2025.
//

import SwiftUI
import API
import SwiftData

public struct CreateUserPage: View {
    
    @Environment(\.networkClient) private var api
    @Environment(\.modelContext) private var context
    @Environment(\.home) private var home
    
    @State private var newName: String = ""
    @State private var isError: Bool = false
    
    public var body: some View {
        ZStack {
            Color.color1.ignoresSafeArea()
            
            VStack {
                Spacer().frame(height: 32)
                Form {
                    TextField("User Name", text: $newName)
                }
                Spacer()
                
                Button(action: { Task { await createUser() }}) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonPlatformProminent()
                .scenePadding()
                .disabled(newName.replacingOccurrences(of: " ", with: "").count < 2)
            }
        }
        .navigationTitle("Create a User")
        .alert("Error", isPresented: $isError) {
            Button(action: { self.isError = false }) { Text("Ok") }
        } message: {
            Text("Your account couldn't be created - make sure your username is unique within the home!")
        }
    }
}

extension CreateUserPage {
    
    func createUser() async {
        do {
            let newUser: UserDTO = try await api.post(Users.create(userName: newName, homeId: home.id))
            let localUser = LocalUser(id: newUser.id, name: newUser.name, homeId: home.id)
            if let key = newUser.key {
                context.insert(localUser)
                try? context.save()
                _ = KeychainStore.setAPIKey(key)
            } else {
                self.isError = true
            }
        } catch {
            print(error)
            self.isError = true
        }
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: LocalHome.self, LocalUser.self, configurations: config)
    
    return NavigationStack() {
        CreateUserPage()
            .environment(\.networkClient, MockClient())
            .environment(\.home, LocalHome(id: "111", name: "Mock Home", joinCode: "XXXXXX", isPrivate: true))
    }
    .modelContainer(container)
}
