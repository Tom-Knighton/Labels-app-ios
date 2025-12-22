//
//  RegisterDeviceRequest.swift
//  API
//
//  Created by Tom Knighton on 22/12/2025.
//

import Foundation
import Codable

@Codable
public struct RegisterDeviceRequest {
    let address: String
    let name: String
    let width: Int
    let height: Int
}
