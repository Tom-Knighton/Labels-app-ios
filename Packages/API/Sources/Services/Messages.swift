//
//  Users.swift
//  API
//
//  Created by Tom Knighton on 21/12/2025.
//

import Foundation

public enum Messages: Endpoint {
    
    case clear(deviceId: String)
    case flash(deviceId: String, hex: String)
    
    public func path() -> String {
        switch self {
        case .clear(let deviceId):
            return "/messages/\(deviceId)/clear"
        case .flash(let deviceId, _):
            return "/messages/\(deviceId)/flash"
        }
    }
    
    public func queryItems() -> [URLQueryItem]? {
        return []
    }
    
    public var body: (any Encodable)? {
        switch self {
        case .flash(_, let hex):
            return FlashRequest(color: hex)
        default:
            return nil
        }
    }
    
    public func mockResponseOk() -> any Decodable {
        switch self {
        case .flash:
            return MessageResponse(accepted: true)
        case .clear:
            return MessageResponse(accepted: true)
        }
    }
}
