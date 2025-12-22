//
//  View+Transform.swift
//  Tomja
//
//  Created by Tom Knighton on 22/12/2025.
//

import SwiftUI

public extension View {
    func transform(@ViewBuilder content: (_ view: Self) -> some View) -> some View {
        content(self)
    }
}
