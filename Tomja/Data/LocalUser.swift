//
//  LocalUser.swift
//  Tomja
//
//  Created by Tom Knighton on 21/12/2025.
//

import Foundation
import SwiftData

@Model
public final class LocalUser {
    @Attribute(.unique) public var id: String
    public var name: String
    public var homeId: String?
    
    public init(id: String, name: String, homeId: String?) {
        self.id = id
        self.name = name
        self.homeId = homeId
    }
}
