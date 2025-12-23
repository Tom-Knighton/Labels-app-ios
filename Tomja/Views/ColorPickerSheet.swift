//
//  ColorPickerSheet.swift
//  Tomja
//
//  Created by Tom Knighton on 23/12/2025.
//


import SwiftUI

struct ColorPickerSheet: View {
    typealias Completion = (_ selected: Color?) -> Void

    private let initialColor: Color
    private let completion: Completion

    @Environment(\.dismiss) private var dismiss
    @State private var selected: Color

    init(initialColor: Color = .white, completion: @escaping Completion) {
        self.initialColor = initialColor
        self.completion = completion
        _selected = State(initialValue: initialColor)
    }

    var body: some View {
        NavigationStack {
            Form {
                ColorPicker("Colour", selection: $selected, supportsOpacity: true)
            }
            .navigationTitle("Pick a colour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        completion(nil)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        completion(selected)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.3), .medium, .large])
        .presentationDragIndicator(.visible)
    }
}
