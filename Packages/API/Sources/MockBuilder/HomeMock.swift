//
//  HomeMock.swift
//  API
//
//  Created by Tom Knighton on 21/12/2025.
//


public class HomeDTOMockBuilder {
    
    public init() {
        
    }
    
    var id: String = "111111111111111"
    var name: String = "Mock Home"
    var isPrivate: Bool = true
    var joinCode: String? = "XXXXXX"
    
    public func withId(_ id: String) -> HomeDTOMockBuilder {
        self.id = id
        return self
    }
    
    public func withName(_ name: String) -> HomeDTOMockBuilder {
        self.name = name
        return self
    }
    
    public func withIsPrivate(_ isPrivate: Bool) -> HomeDTOMockBuilder {
        self.isPrivate = isPrivate
        return self
    }
    
    public func withJoinCode(_ code: String?) -> HomeDTOMockBuilder {
        self.joinCode = code
        return self
    }
   
    public func build() -> HomeDTO {
        HomeDTO(id: id, name: name, isPrivate: isPrivate, joinCode: joinCode)
    }
}
