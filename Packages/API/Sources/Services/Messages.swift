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
    case sendImage(deviceId: String, imageData: Data)
    
    public func path() -> String {
        switch self {
        case .clear(let deviceId):
            return "/messages/\(deviceId)/clear"
        case .flash(let deviceId, _):
            return "/messages/\(deviceId)/flash"
        case .sendImage(let deviceId, _):
            return "/messages/\(deviceId)/image"
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
    
    public var multipartData: (data: Data, boundary: String)? {
        switch self {
        case .sendImage(_, let imageData):
            let boundary = "Boundary-\(UUID().uuidString)"
            var data = Data()
            
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
            data.append(imageData)
            data.append("\r\n".data(using: .utf8)!)
            data.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            return (data, boundary)
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
        case .sendImage:
            return MessageResponse(accepted: true)
        }
    }
}
