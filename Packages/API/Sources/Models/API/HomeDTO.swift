//
//  HomeDTO.swift
//  API
//
//  Created by Tom Knighton on 21/12/2025.
//

import Codable

@Codable
public struct HomeDTO: Sendable, Identifiable, Equatable, Hashable {
    
    public let id: String
    public let name: String
    public let isPrivate: Bool
    public let joinCode: String?
    
    public var users: [UserDTO] = []
}
