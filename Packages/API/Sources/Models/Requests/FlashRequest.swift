//
//  FlashRequest.swift
//  API
//
//  Created by Tom Knighton on 22/12/2025.
//

import Foundation

public struct FlashRequest: Codable {
    let color: String
    
    public init(color: String) {
        self.color = color
    }
}
