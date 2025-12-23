//
//  Image+Base64.swift
//  Tomja
//
//  Created by Tom Knighton on 23/12/2025.
//

import SwiftUI

extension Image {
    public init(base64JPEG dataURL: String) {
        let prefix = "data:image/jpeg;base64,"
        let base64String = dataURL.hasPrefix(prefix)
        ? String(dataURL.dropFirst(prefix.count))
        : dataURL
        
        guard
            let data = Data(base64Encoded: base64String),
            let uiImage = UIImage(data: data)
        else {
            self = Image(systemName: "error")
            return
        }
        
        self = Image(uiImage: uiImage)
    }
}
