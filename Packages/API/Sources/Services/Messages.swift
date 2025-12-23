//
//  Users.swift
//  API
//
//  Created by Tom Knighton on 21/12/2025.
//

import Foundation

public enum Messages: Endpoint {
    
    case clear(deviceId: String)
    
    public func path() -> String {
        switch self {
        case .clear(let deviceId):
            return "/messages/\(deviceId)/clear"
        }
    }
    
    public func queryItems() -> [URLQueryItem]? {
        return []
    }
    
    public var body: (any Encodable)? {
        switch self {
        default:
            return nil
        }
    }
    
    public func mockResponseOk() -> any Decodable {
        switch self {
        case .clear:
            return MessageResponse(accepted: true)
        }
    }
}
