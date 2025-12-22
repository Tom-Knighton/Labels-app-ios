//
//  ESLViewport.swift
//  Tomja
//
//  Created by Tom Knighton on 22/12/2025.
//

import SwiftUI

struct ESLViewport<Content: View>: View {
    let sizePx: CGSize
    @ViewBuilder var content: () -> Content

    private var aspect: CGFloat { sizePx.width / sizePx.height }

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(aspect, contentMode: .fit)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
