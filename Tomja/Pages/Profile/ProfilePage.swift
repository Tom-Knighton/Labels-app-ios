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
import CustomAlert

public struct ProfilePage: View {
    
    @Environment(\.networkClient) private var api
    @State private var isLoading: Bool = false
    @State private var devices: [DeviceDTO] = []
    @State private var showAdd: Bool = false
    @State private var loadTask: Task<Void, Never>?
    @State private var message: String? = nil
    @State private var sending: Bool = false
    @State private var showFlashSheetForDevice: DeviceDTO? = nil
    @State private var showCanvasForDevice: DeviceDTO? = nil
        
    private var alertIsPresented: Binding<Bool> {
        Binding(
            get: { message != nil },
            set: { isPresented in
                if !isPresented {
                    message = nil
                }
            }
        )
    }
    
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
                    
                    preview(for: device)
                    
                    HStack {
                        Button(action: { Task { await clearScreen(for: device) }}) {
                            Text("Clear Screen")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { self.showFlashSheetForDevice = device }) {
                            Text("Flash")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { self.showCanvasForDevice = device }) {
                            Text("Set Image")
                        }
                        .buttonStyle(.bordered)
                    }
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
            await load()
        }
        .refreshable(action: {
            await load()
        })
        .onReceive(NotificationCenter.default.publisher(for: .deviceUpdated), perform: { _ in
            Task { await load() }
        })
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
        .sheet(item: $showFlashSheetForDevice, content: { device in
            ColorPickerSheet { selected in
                if let selected {
                    Task {
                        await flashDevice(for: device.id, colour: selected)
                    }
                }
            }
        })
        .fullScreenCover(item: $showCanvasForDevice, content: { device in
            NavigationStack {
                PencilKitCanvasEditor(pixelSize: CGSize(width: device.ble?.width ?? 400, height: device.ble?.height ?? 300), stickerAssets: ["sticker_star"]) { image in
                    Task {
                        await sendImage(for: device.id, image: image)
                    }
                }
                    .navigationTitle("Editor")
            }
        })
        .alert("Info", isPresented: alertIsPresented) {
            Button(action: { self.message = nil }) { Text("Ok") }
        } message: {
            Text(self.message ?? "")
        }
        .customAlert("Sending...", isPresented: $sending) {
            Text("Sending the request, this may take a few seconds...")
            ProgressView()
        } actions: {}
    }
}

extension ProfilePage {
    
    @ViewBuilder
    private func preview(for device: DeviceDTO) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.accentColor, style: .init(lineWidth: 1))
            
            ESLViewport(sizePx: .init(width: (device.ble?.width ?? 400), height: (device.ble?.height ?? 300))) {
                if let preview = device.shadow?.currentImagePreviewBase64 {
                    Image(base64JPEG: preview)
                        .resizable()
                        .aspectRatio(CGFloat(device.ble?.width ?? 400) / CGFloat(device.ble?.height ?? 300), contentMode: .fill)
                    
                } else {
                    RoundedRectangle(cornerRadius: 5)
                }
            }
            .shadow(radius: 3)
        }
        .padding(6)
    }
    
    func deleteDevice(device: DeviceDTO) async {
        do {
            if try await api.delete(Devices.delete(id: device.id)) {
                self.devices.removeAll(where: { $0.id == device.id })
            }
        } catch {
            print(error)
        }
    }
    
    func clearScreen(for device: DeviceDTO) async {
        self.sending = true
        defer { self.sending = false }
        
        do {
            let status: MessageResponse = try await api.post(Messages.clear(deviceId: device.id))
            if !status.accepted {
                self.message = "Something went wrong sending the clear command - please try again later."
                return
            }
            
            self.message = "The request to clear the screen has been sent - it may take up to a minute to update."
        } catch {
            print(error)
            self.message = "Something went wrong sending the clear command - please try again later."
        }
    }
    
    func flashDevice(for deviceId: String, colour: Color) async {
        self.sending = true
        defer { self.sending = false }
        
        do {
            let status: MessageResponse = try await api.post(Messages.flash(deviceId: deviceId, hex: colour.hexString() ?? "#FFFFFF"))
            if !status.accepted {
                self.message = "Something went wrong sending the flash request - please try again later."
                return
            }
            
            self.message = "The flash request has been sent - it may take up to a minute to flash."
        } catch {
            print(error)
            self.message = "Something went wrong sending the flash request - please try again later."
        }
    }
    
    func sendImage(for deviceId: String, image: UIImage) async {
        self.sending = true
        defer { self.sending = false }
        
        do {
            let status: MessageResponse = try await api.post(Messages.sendImage(deviceId: deviceId, imageData: image.pngData() ?? Data()))
            if !status.accepted {
                self.message = "Something went wrong sending the image request - please try again later."
                return
            }
            
            self.message = "The image request has been sent - it may take up to a minute to send."
        } catch {
            print(error)
            self.message = "Something went wrong sending the image request - please try again later."
        }
    }
    
    func load() async {
        self.loadTask?.cancel()
        
        self.loadTask = Task {
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


#Preview {
    NavigationStack {
        ProfilePage()
            .environment(\.home, LocalHome(id: "1", name: "Tom's Home", joinCode: "XXXXXX", isPrivate: true))
            .environment(\.user, LocalUser(id: "2", name: "Tom", homeId: "1"))
            .environment(\.networkClient, MockClient())
    }
}
