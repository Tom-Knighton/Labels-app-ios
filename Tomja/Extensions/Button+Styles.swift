//
//  Button+Styles.swift
//  Tomja
//
//  Created by Tom Knighton on 21/12/2025.
//

import SwiftUI

extension View {
    func buttonPlatformProminent() -> some View {
        modifier(ButtonPlatformProminentModifier())
    }
    
    func buttonPlatformBordered() -> some View {
        modifier(ButtonPlatformBorderedModifier())
    }
}

struct ButtonPlatformProminentModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glassProminent)
        } else {
            content
                .buttonStyle(.borderedProminent)
        }
    }
}

struct ButtonPlatformBorderedModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glass)
        } else {
            content
                .buttonStyle(.bordered)
        }
    }
}
