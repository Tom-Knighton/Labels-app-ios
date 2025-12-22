//
//  Homes.swift
//  API
//
//  Created by Tom Knighton on 21/12/2025.
//

import Foundation

public enum Homes: Endpoint {
    
    case getForCode(code: String)
    case my
    
    public func path() -> String {
        switch self {
        case .getForCode(let code):
            return "homes/\(code)"
        case .my:
            return "homes/my"
        }
   
    }
    
    public func queryItems() -> [URLQueryItem]? {
        return []
    }
    
    public var body: (any Encodable)? {
        return nil
    }
    
    public func mockResponseOk() -> any Decodable {
        switch self {
        case .getForCode:
            return HomeDTOMockBuilder()
                .build()
        case .my:
            return HomeDTOMockBuilder()
                .withName("Mock Home")
                .withId("1")
                .withUsers([
                    UserDTOMockBuilder()
                        .withId("2")
                        .withName("Tom")
                        .withDevices([
                            DeviceDTOMockBuilder()
                                .withId("A")
                                .withName("Tom's Device")
                                .withOwner("2")
                                .withHomeId("1")
                                .build()
                        ])
                        .build(),
                    UserDTOMockBuilder()
                        .withId("3")
                        .withName("Maja")
                        .withDevices([
                            DeviceDTOMockBuilder()
                                .withId("B")
                                .withName("Maja's Device")
                                .withOwner("3")
                                .withHomeId("1")
                                .withSize(width: 300, height: 100)
                                .build()
                        ])
                        .build()
                ])
                .build()
        }
    }
}
