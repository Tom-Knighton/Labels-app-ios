//
//  CreateHomeRequest.swift
//  API
//
//  Created by Tom Knighton on 22/12/2025.
//

import Foundation

public struct CreateHomeRequest: Codable {
    let name: String
    
    public init(name: String) {
        self.name = name
    }
}
