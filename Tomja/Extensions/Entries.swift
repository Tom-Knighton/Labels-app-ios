//
//  Entries.swift
//  Tomja
//
//  Created by Tom Knighton on 21/12/2025.
//

import SwiftUI
import API

public extension EnvironmentValues {
    @Entry var networkClient: any NetworkClient = APIClient(host: "")
    @Entry var home: LocalHome = .init(id: "", name: "", joinCode: "", isPrivate: false)
    @Entry var user: LocalUser = .init(id: "", name: "", homeId: nil)
    @Entry var notificationsDisabled: Bool = false
}
