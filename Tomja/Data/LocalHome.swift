//
//  LocalHome.swift
//  Tomja
//
//  Created by Tom Knighton on 21/12/2025.
//

import Foundation
import SwiftData

@Model
public final class LocalHome {
    @Attribute(.unique) public var id: String
    public var name: String
    public var joinCode: String
    public var isPrivate: Bool
    
    public init(id: String, name: String, joinCode: String, isPrivate: Bool) {
        self.id = id
        self.name = name
        self.joinCode = joinCode
        self.isPrivate = isPrivate
    }
}
