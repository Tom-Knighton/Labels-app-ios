//
//  UserDTO.swift
//  API
//
//  Created by Tom Knighton on 21/12/2025.
//

public struct UserDTO: Codable, Sendable, Identifiable, Equatable, Hashable {
    
    public let id: String
    public let name: String
    public let homeId: String
    public let isActive: Bool
    public let apiKey: String?
}
