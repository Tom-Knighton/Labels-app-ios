//
//  CreateUserRequest.swift
//  API
//
//  Created by Tom Knighton on 22/12/2025.
//

import Foundation

public struct CreateUserRequest: Codable {
    let name: String
    let homeId: String
    
    public init(name: String, homeId: String) {
        self.name = name
        self.homeId = homeId
    }
}
