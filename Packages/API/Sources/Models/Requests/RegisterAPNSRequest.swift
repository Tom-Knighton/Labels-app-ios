//
//  RegisterAPNSRequest.swift
//  API
//
//  Created by Tom Knighton on 22/12/2025.
//

import Foundation

public struct RegisterAPNSRequest: Codable {
    let token: String
    let device: String
    
    public init(token: String, device: String) {
        self.token = token
        self.device = device
    }
}
