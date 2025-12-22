//
//  HomeMock.swift
//  API
//
//  Created by Tom Knighton on 21/12/2025.
//

import Foundation

public class DeviceDTOMockBuilder {
    
    public init() {
        
    }
    
    var id: String = "111111111111111"
    var homeId: String = "1"
    var ownerId: String = "2"
    var name: String = "Tom's Label"
    var address: String = "FF:FF:16:64:0B:B6"
    var currentAsset: String? = nil
    var isFlashing: Bool = false
    var lastSuccessful: Date? = nil
    var lastSeen: Date? = nil
    var lastError: Date? = nil
    var createdAt: Date = .now
    var updatedAt: Date = .now
    var width: Int = 400
    var height: Int = 300
    
    public func withId(_ id: String) -> DeviceDTOMockBuilder {
        self.id = id
        return self
    }
    
    public func withHomeId(_ id: String) -> DeviceDTOMockBuilder {
        self.homeId = id
        return self
    }
    
    public func withOwner(_ id: String) -> DeviceDTOMockBuilder {
        self.ownerId = id
        return self
    }
    
    public func withName(_ name: String) -> DeviceDTOMockBuilder {
        self.name = name
        return self
    }
    
    public func withAddress(_ address: String) -> DeviceDTOMockBuilder {
        self.address = address
        return self
    }
    
    public func withAsset(_ assetId: String) -> DeviceDTOMockBuilder {
        self.currentAsset = assetId
        return self
    }
    
    public func withFlashing(_ isFlashing: Bool) -> DeviceDTOMockBuilder {
        self.isFlashing = isFlashing
        return self
    }
    
    public func withSuccess(_ lastSuccess: Date?) -> DeviceDTOMockBuilder {
        self.lastSuccessful = lastSuccess
        return self
    }
    
    public func withSeen(_ lastSeen: Date?) -> DeviceDTOMockBuilder {
        self.lastSeen = lastSeen
        return self
    }
    
    public func withError(_ lastError: Date?) -> DeviceDTOMockBuilder {
        self.lastError = lastError
        return self
    }
    
    public func withCreated(_ created: Date) -> DeviceDTOMockBuilder {
        self.createdAt = created
        return self
    }
    
    public func withUpdated(_ updated: Date) -> DeviceDTOMockBuilder {
        self.updatedAt = updated
        return self
    }
    
    public func withSize(width: Int, height: Int) -> DeviceDTOMockBuilder {
        self.height = height
        self.width = width
        return self
    }
   
    public func build() -> DeviceDTO {
        DeviceDTO(id: id, homeId: homeId, ownerUserId: ownerId, name: name, ble: .init(address: address, width: width, height: height), shadow: .init(currentImageAssetId: currentAsset, isFlashing: isFlashing, lastSuccessfulActionAt: lastSuccessful, lastSeenAt: lastSeen, lastError: lastError), createdAt: createdAt, updatedAt: updatedAt)
    }
}
