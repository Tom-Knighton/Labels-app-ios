//
//  UserHomeRowView.swift
//  Tomja
//
//  Created by Tom Knighton on 22/12/2025.
//

import SwiftUI
import API

public struct UserHomeRowView: View {
    
    public let user: UserDTO
    
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
                        Button(action: {}) {
                            Label("New Message", systemImage: "paperplane")
                                .bold()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: {}) {
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
    }
}
