//
//  Homes.swift
//  API
//
//  Created by Tom Knighton on 21/12/2025.
//

import Foundation

public enum Homes: Endpoint {
    
    case getForCode(code: String)
    
    public func path() -> String {
        switch self {
        case .getForCode(let code):
            return "homes/\(code)"
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
        }
    }
}
