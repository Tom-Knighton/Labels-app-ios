//
//  CreateHomePage.swift
//  Tomja
//
//  Created by Tom Knighton on 21/12/2025.
//

import SwiftUI
import API
import SwiftData

struct CreateHomePage: View {
    
    @Environment(\.modelContext) private var context
    @Environment(\.networkClient) private var api
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.color1.ignoresSafeArea()
                
                VStack {
                    Text("Create a new Home")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer().frame(height: 12)
                    Text("Give your new home a name:")
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                    Spacer()
                    
                    Form {
                        TextField("New name", text: $name)
                    }
                    .scrollContentBackground(.hidden)
                    
                    Spacer()
                    Spacer()

                    Button(action: { Task {
                        if let home = await createHome(with: self.name) {
                            self.saveHome(home)
                        }
                    }}) {
                        
                        if isLoading {
                            ProgressView()
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create")
                                .font(.title3.bold())
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonPlatformProminent()
                    .disabled(name.count < 2 || isLoading)
                }
                .scenePadding()
            }
            .fontDesign(.rounded)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { self.dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

extension CreateHomePage {
    public func createHome(with name: String) async -> HomeDTO? {
        self.isLoading = true
        defer { self.isLoading = false }
        
        do {
            let home: HomeDTO? = try await api.post(Homes.create(name: name))
            return home
        } catch {
            print(error)
            return nil
        }
    }
    
    func saveHome(_ home: HomeDTO) {
        self.isLoading = true
        defer { self.isLoading = false }
        do {
            context.insert(LocalHome(id: home.id, name: home.name, joinCode: home.joinCode ?? "", isPrivate: home.isPrivate))
            try context.save()
        } catch {
            print(error)
        }
        
    }
}

#Preview {
    CreateHomePage()
        .environment(\.networkClient, MockClient())
}
