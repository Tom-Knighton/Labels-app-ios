//
//  ProfilePage.swift
//  Tomja
//
//  Created by Tom Knighton on 22/12/2025.
//

import SwiftUI
import API
import CodeScanner
internal import AVFoundation

public struct ProfilePage: View {
    
    @Environment(\.networkClient) private var api
    @State private var isLoading: Bool = false
    @State private var devices: [DeviceDTO] = []
    @State private var showAdd: Bool = false
        
    public var body: some View {
        ZStack {
            Color.color1.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
            } else {
                if devices.isEmpty {
                    ContentUnavailableView("No Devices", systemImage: "tag.slash", description: Text("You haven't added any devices yet! Add one now to let others send you messages."))
                }
            }
            
            List(devices) { device in
                VStack {
                    HStack {
                        Text(device.name)
                            .font(.headline.bold())
                        
                        Spacer()
                        
                        Menu {
                            Button(action: { Task { await deleteDevice(device: device)}}) {
                                Text("Remove")
                                    .foregroundStyle(.red)
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.accentColor, style: .init(lineWidth: 1))
                        
                        ESLViewport(sizePx: .init(width: device.ble.width, height: device.ble.height)) {
                            RoundedRectangle(cornerRadius: 5)
                        }
                        .shadow(radius: 3)
                    }
                    .padding(6)
                }
                .padding()
                .background(Color.color2)
                .clipShape(.rect(cornerRadius: 10))
                .shadow(radius: 3)
                .listRowSeparator(.hidden)
                .listRowInsets(.none)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("My Devices")
        .toolbar {
            ToolbarItem {
                Button(action: { self.showAdd.toggle() }) {
                    Image(systemName: "plus")
                }
            }
        }
        .fontDesign(.rounded)
        .task {
            self.isLoading = true
            defer { self.isLoading = false }
            do {
                let devices: [DeviceDTO] = try await api.get(Devices.my)
                self.devices = devices
            } catch {
                print(error)
            }
        }
        .sheet(isPresented: $showAdd) {
            RegisterDeviceSheet()
                .interactiveDismissDisabled()
                .onDisappear {
                    Task {
                        self.isLoading = true
                        defer { self.isLoading = false }
                        do {
                            let devices: [DeviceDTO] = try await api.get(Devices.my)
                            self.devices = devices
                        } catch {
                            print(error)
                        }
                    }
                }
        }
    }
}

extension ProfilePage {
    
    func deleteDevice(device: DeviceDTO) async {
        do {
            if try await api.delete(Devices.delete(id: device.id)) {
                self.devices.removeAll(where: { $0.id == device.id })
            }
        } catch {
            print(error)
        }
    }
}


#Preview {
    NavigationStack {
        ProfilePage()
            .environment(\.home, LocalHome(id: "1", name: "Tom's Home", joinCode: "XXXXXX", isPrivate: true))
            .environment(\.user, LocalUser(id: "2", name: "Tom", homeId: "1"))
            .environment(\.networkClient, MockClient())
    }
}
