//
//  UserHomeRowView.swift
//  Tomja
//
//  Created by Tom Knighton on 22/12/2025.
//

import SwiftUI
import API
import CustomAlert

public struct UserHomeRowView: View {
    
    @Environment(\.networkClient) private var api
    public let user: UserDTO
    
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
            Color.color2
            
            VStack {
                HStack {
                    Text(user.name)
                        .font(.headline.bold())
                    Spacer()
                    Image(systemName: "light.beacon.min")
                }
                
                if let device = user.devices.first {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.accentColor, style: .init(lineWidth: 1))
                        
                        ESLViewport(sizePx: .init(width: (device.ble?.width ?? 400), height: (device.ble?.height ?? 300))) {
                            
                            if let preview = device.shadow?.currentImagePreviewBase64 {
                                Image(base64JPEG: preview)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                        }
                        .shadow(radius: 3)
                    }
                    
                    HStack {
                        Button(action: { self.showCanvasForDevice = device }) {
                            Label("New Message", systemImage: "paperplane")
                                .bold()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: { self.showFlashSheetForDevice = device }) {
                            Label("Flash", systemImage: "light.beacon.max.fill")
                                .bold()
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                    }
                } else {
                    ContentUnavailableView("No Devices", systemImage: "tag.slash", description: Text("This user hasn't registerd any labels yet!"))
                }
   
                Spacer()
            }
            .padding()
        }
        .frame(minHeight: 50)
        .clipShape(.rect(cornerRadius: 10))
        .transform { view in
            if #available(iOS 26.0, *) {
                view.glassEffect(in: .rect(cornerRadius: 10))
            } else {
                view
            }
        }
        .shadow(radius: 3)
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

extension UserHomeRowView {
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
}
