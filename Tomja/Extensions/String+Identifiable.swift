//
//  String+Identifiable.swift
//  Tomja
//
//  Created by Tom Knighton on 23/12/2025.
//

extension String: @retroactive Identifiable {
    public var id: String {
        self
    }
}
