//
//  HomeDTO.swift
//  API
//
//  Created by Tom Knighton on 21/12/2025.
//

public struct HomeDTO: Codable, Sendable, Identifiable, Equatable, Hashable {
    
    public let id: String
    public let name: String
    public let isPrivate: Bool
    public let joinCode: String?
}
