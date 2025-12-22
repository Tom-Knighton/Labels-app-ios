//
//  HomeMock.swift
//  API
//
//  Created by Tom Knighton on 21/12/2025.
//


public class UserDTOMockBuilder {
    
    public init() {
        
    }
    
    var id: String = "2222"
    var name: String = "Mock User"
    var homeId: String = "111111111111111"
    var isActive: Bool = true
    var apiKey: String? = nil
    var devices: [DeviceDTO] = []
    
    public func withId(_ id: String) -> UserDTOMockBuilder {
        self.id = id
        return self
    }
    
    public func withName(_ name: String) -> UserDTOMockBuilder {
        self.name = name
        return self
    }
    
    public func withIsActive(_ isActive: Bool) -> UserDTOMockBuilder {
        self.isActive = isActive
        return self
    }
    
    public func withHomeId(_ homeId: String) -> UserDTOMockBuilder {
        self.homeId = homeId
        return self
    }
    
    public func withKey(_ key: String?) -> UserDTOMockBuilder {
        self.apiKey = key
        return self
    }
    
    public func withDevices(_ devices: [DeviceDTO]) -> UserDTOMockBuilder {
        self.devices = devices
        return self
    }
   
    public func build() -> UserDTO {
        UserDTO(id: id, name: name, homeId: homeId, isActive: isActive, apiKey: apiKey, devices: devices)
    }
}
