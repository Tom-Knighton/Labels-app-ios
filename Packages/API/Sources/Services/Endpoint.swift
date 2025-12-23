//
//  Endpoint.swift
//  API
//
//  Created by Tom Knighton on 25/08/2025.
//

import Foundation

public protocol Endpoint: Sendable {
    func path() -> String
    func queryItems() -> [URLQueryItem]?
    func mockResponseOk() -> any Decodable
    var body: Encodable? { get }
    var multipartData: (data: Data, boundary: String)? { get }
}

public extension Endpoint {
    var body: Encodable? {
        nil
    }
    
    var multipartData: (data: Data, boundary: String)? {
        nil
    }
}
