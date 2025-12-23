//
//  RegisterDeviceSheet.swift
//  Tomja
//
//  Created by Tom Knighton on 22/12/2025.
//

import SwiftUI
import API
import CodeScanner
internal import AVFoundation

private enum DeviceType {
    case small
    case medium
    case large
}

public struct RegisterDeviceSheet: View {
    
    @Environment(\.networkClient) private var api
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: DeviceType? = .small
    @State private var name: String = ""
    @State private var address: String? = nil
    @State private var showScanner: Bool = false
    
    @State private var loading: Bool = false
    
    @State private var error: String? = nil
    @State private var showError: Bool = false
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.color1.ignoresSafeArea()
                
                VStack {
                    Form {
                        Picker("Device Type", selection: $selectedType) {
                            Text("Small")
                                .tag(DeviceType.small)
                            Text("Large")
                                .tag(DeviceType.large)
                        }
                        
                        TextField("Device Name", text: $name, prompt: Text("Give your device a new name"))
                        
                        if let address {
                            Text("Device Address: \(address)")
                        } else {
                            Button(action: { self.showScanner = true }) {
                                Text("Scan Device:")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    
                    Spacer()
                    
                    Button(action: { Task { await self.register() }}) {
                        if loading {
                            ProgressView()
                        } else {
                            Text("Register")
                                .font(.title3.bold())
                                .frame(maxWidth: .infinity)
                        }
                        
                    }
                    .padding()
                    .buttonPlatformProminent()
                    .disabled(loading)
                    .animation(.spring, value: loading)
                }
            }
            .navigationTitle("Register Device")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { self.dismiss() }) {
                        Image(systemName: "xmark")
                    }
                    .disabled(loading)
                }
            }
        }
        .sheet(isPresented: $showScanner) {
            CodeScannerView(codeTypes: [.code128], scanMode: .once, showViewfinder: true, shouldVibrateOnSuccess: true) { result in
                if case .success(let code) = result {
                    self.showScanner = false
                    self.address = "66:66:\(insertColonsEveryTwoCharacters(code.string))"
                }
            }
        }
        .alert(error ?? "Error", isPresented: $showError) {
            Button(action: { self.showError = false} ) {
                Text("Ok")
            }
        }
    }
}

extension RegisterDeviceSheet {
    
    func register() async {
        self.loading = true
        defer { self.loading = false }
        
        if address == nil || address?.count != 17 {
            self.error = "Please scan the device's barcode to set it's address"
        }
        
        if self.selectedType == nil {
            self.error = "Please select a device type"
        }
        
        if self.name.isEmpty {
            self.error = "Please enter a name for the device"
        }
        
        if let _ = self.error {
            self.showError = true
            return
        }
        
        do {
            let sizing = sizing(for: self.selectedType ?? .small)
            let _: DeviceDTO = try await api.post(Devices.register(address: address ?? "", name: name, width: sizing.width, height: sizing.height))
            self.dismiss()
        } catch {
            print(error)
            self.error = "Couldn't register this device - have you already registered it?"
            self.showError = true
        }
    }
    
    fileprivate func sizing(for type: DeviceType) -> (width: Int, height: Int) {
        switch type {
        case .small:
            return (296, 128)
        case .medium:
            return (296, 128)
        case .large:
            return (400, 300)
        }
    }
    
    func insertColonsEveryTwoCharacters(_ input: String) -> String {
        var result: [Substring] = []
        var index = input.startIndex
        
        while index < input.endIndex {
            let nextIndex = input.index(index, offsetBy: 2, limitedBy: input.endIndex) ?? input.endIndex
            result.append(input[index..<nextIndex])
            index = nextIndex
        }
        
        return result.joined(separator: ":")
    }


}

#Preview {
    VStack {}
        .sheet(isPresented: .constant(true)) {
            RegisterDeviceSheet()
                .environment(\.home, LocalHome(id: "1", name: "Tom's Home", joinCode: "XXXXXX", isPrivate: true))
                .environment(\.user, LocalUser(id: "2", name: "Tom", homeId: "1"))
                .environment(\.networkClient, MockClient())
                .interactiveDismissDisabled()
        }
}
