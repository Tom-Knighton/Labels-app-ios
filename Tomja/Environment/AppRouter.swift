//
//  AppRouter.swift
//  Tomja
//
//  Created by Tom Knighton on 22/12/2025.
//

import AppRouter
import SwiftUI

public enum AppTab: String, CaseIterable, TabType {
    case home
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .home:
            return "house"
        }
    }
    
    public var title: String {
        switch self {
        case .home:
            return "Home"
        }
    }
}

public enum Destination: DestinationType {
    public static func from(path: String, fullPath: [String], parameters: [String : String]) -> Destination? {
        return nil
    }
    
    case home
}

public enum Sheet: SheetType {
    
    public var id: Int { hashValue }
}

public typealias AppRouter = Router<AppTab, Destination, Sheet>
