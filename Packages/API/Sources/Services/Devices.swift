//
//  Users.swift
//  API
//
//  Created by Tom Knighton on 21/12/2025.
//

import Foundation

public enum Devices: Endpoint {
    
    case my
    case register(address: String, name: String, width: Int, height: Int)
    case delete(id: String)
    
    public func path() -> String {
        switch self {
        case .my:
            return "devices"
        case .register:
            return "devices"
        case .delete(let id):
            return "devices/\(id)"
        }
    }
    
    public func queryItems() -> [URLQueryItem]? {
        return []
    }
    
    public var body: (any Encodable)? {
        switch self {
        case .register(let address, let name, let width, let height):
            let request = RegisterDeviceRequest(address: address, name: name, width: width, height: height)
            return request
        default:
            return nil
        }
    }
    
    public func mockResponseOk() -> any Decodable {
        switch self {
        case .register:
            let device = DeviceDTOMockBuilder().build()
            return device
        case .delete:
            return ""
        case .my:
            let devices = [
                DeviceDTOMockBuilder()
                    .withId("A")
                    .withName("Tom's Device")
                    .withOwner("2")
                    .withHomeId("1")
                    .build(),
                DeviceDTOMockBuilder()
                    .withId("B")
                    .withName("Tom's Small Device")
                    .withOwner("2")
                    .withHomeId("1")
                    .withSize(width: 300, height: 100)
                    .build()
            ]
            return devices
        }
    }
}
