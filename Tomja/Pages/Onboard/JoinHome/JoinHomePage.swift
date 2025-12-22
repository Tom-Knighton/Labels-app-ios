//
//  JoinHomePage.swift
//  Tomja
//
//  Created by Tom Knighton on 21/12/2025.
//

import SwiftUI
import API
import SwiftData

struct JoinHomePage: View {
    
    @Environment(\.modelContext) private var context
    @Environment(\.networkClient) private var api
    @Environment(\.dismiss) private var dismiss
    
    @State private var otp: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.color1.ignoresSafeArea()
                
                VStack {
                    Text("Join a Home")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer().frame(height: 12)
                    Text("Enter the 6-digit code of the home you wish to join below")
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                    Spacer()
                    
                    OTPPassView(value: $otp) { val in
                        if val.count == 6 {
                            if let home = await loadHome(for: val) {
                                self.saveHome(home)
                                return .valid
                            }
                            return .invalid
                        }
                        
                        return .typing
                    }
                    
                    
                    Spacer()
                    Spacer()

                    Button(action: { Task {
                        if let home = await loadHome(for: self.otp) {
                            self.saveHome(home)
                        }
                    }}) {
                        
                        if isLoading {
                            ProgressView()
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Join")
                                .font(.title3.bold())
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonPlatformProminent()
                    .disabled(otp.count != 6 || isLoading)
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

extension JoinHomePage {
    public func loadHome(for code: String) async -> HomeDTO? {
        self.isLoading = true
        defer { self.isLoading = false }
        
        do {
            let home: HomeDTO? = try await api.get(Homes.getForCode(code: code))
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
    JoinHomePage()
        .environment(\.networkClient, MockClient())
}
