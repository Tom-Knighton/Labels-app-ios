//
//  DeviceDTO.swift
//  API
//
//  Created by Tom Knighton on 22/12/2025.
//

import Foundation

public struct DeviceDTO: Codable, Sendable, Equatable, Identifiable, Hashable {
    
    public let id: String
    public let homeId: String
    public let ownerUserId: String
    public let name: String
    public let ble: DeviceBLE
    public let shadow: DeviceShadow
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(id: String, homeId: String, ownerUserId: String, name: String, ble: DeviceBLE, shadow: DeviceShadow, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.homeId = homeId
        self.ownerUserId = ownerUserId
        self.name = name
        self.ble = ble
        self.shadow = shadow
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct DeviceBLE: Codable, Equatable, Sendable, Hashable {
    public let address: String
    public let width: Int
    public let height: Int
    
    public init(address: String, width: Int, height: Int) {
        self.address = address
        self.width = width
        self.height = height
    }
}

public struct DeviceShadow: Codable, Equatable, Sendable, Hashable {
    public let currentImageAssetId: String?
    public let isFlashing: Bool
    public let lastSuccessfulActionAt: Date?
    public let lastSeenAt: Date?
    public let lastError: Date?
    
    public init(currentImageAssetId: String?, isFlashing: Bool, lastSuccessfulActionAt: Date?, lastSeenAt: Date?, lastError: Date?) {
        self.currentImageAssetId = currentImageAssetId
        self.isFlashing = isFlashing
        self.lastSuccessfulActionAt = lastSuccessfulActionAt
        self.lastSeenAt = lastSeenAt
        self.lastError = lastError
    }
}
