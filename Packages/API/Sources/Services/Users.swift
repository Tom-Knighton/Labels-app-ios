//
//  Users.swift
//  API
//
//  Created by Tom Knighton on 21/12/2025.
//

import Foundation

public enum Users: Endpoint {
    
    case getForHome(homeId: String, code: String)
    case authAs(userId: String, code: String)
    case create(userName: String, homeId: String)
    
    public func path() -> String {
        switch self {
        case .getForHome(let homeId, let code):
            return "users/home/\(homeId)/\(code)"
        case .authAs(let userId, let code):
            return "users/auth/\(userId)/home/\(code)"
        case .create:
            return "users"
        }
    }
    
    public func queryItems() -> [URLQueryItem]? {
        return []
    }
    
    public var body: (any Encodable)? {
        switch self {
        case .create(let name, let home):
            return CreateUserRequest(name: name, homeId: home)
        default:
            return nil
        }
    }
    
    public func mockResponseOk() -> any Decodable {
        switch self {
        case .authAs:
            let user = UserDTOMockBuilder().build()
            return user
        case .getForHome:
            let user1 = UserDTOMockBuilder().withId("2").withName("Tom").build()
            let user2 = UserDTOMockBuilder().withId("3").withName("Maja").build()
            let resp: [UserDTO] = [user1, user2]
            return resp
        case .create:
            return UserDTOMockBuilder().build()
        }
    }
}
