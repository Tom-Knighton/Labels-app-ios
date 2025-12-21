//
//  OTPPassView.swift
//  Tomja
//
//  Created by Tom Knighton on 21/12/2025.
//

import SwiftUI

enum OTPTypingState {
    case typing
    case valid
    case invalid
}

struct OTPPassView: View {
    
    @State private var state: OTPTypingState = .typing
    @State private var invalidTrigger: Bool = false
    @State private var successTrigger: Bool = false
    @State private var inputTrigger: Bool = false
    
    @Binding var value: String
    @FocusState private var isActive: Bool
    
    var onChange: (String) async -> OTPTypingState
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<6, id: \.self) { index in
                characterView(index)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: value)
        .animation(.easeInOut(duration: 0.2), value: isActive)
        .phaseAnimator([0, 10, -10, 10, -5, 5, 0], trigger: invalidTrigger, content: { content, offset in
            content
                .offset(x: offset)
        }, animation: { _ in
                .linear(duration: 0.06)
        })
        .compositingGroup()
        .background {
            TextField("", text: $value)
                .focused($isActive)
                .mask(alignment: .trailing) {
                    Rectangle()
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                }
                .textContentType(.oneTimeCode)
                .allowsHitTesting(false)
                .selectionDisabled()
                .autocorrectionDisabled()
        }
        .contentShape(.rect)
        .onTapGesture {
            isActive = true
        }
        .onChange(of: value) { old, new in
            let newVal = new.replacingOccurrences(of: " ", with: "")
            value = String(newVal.prefix(6))
            Task { @MainActor in
                state = await onChange(value)
                if state == .invalid {
                    invalidTrigger.toggle()
                } else if state == .valid {
                    successTrigger.toggle()
                }
            }
        }
        .sensoryFeedback(.impact, trigger: inputTrigger)
        .sensoryFeedback(.error, trigger: invalidTrigger)
        .sensoryFeedback(.success, trigger: successTrigger)
    }
    
    @ViewBuilder
    private func characterView(_ index: Int) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(borderColour(index: index), lineWidth: 1.2)
            .frame(width: 50, height: 50)
            .overlay {
                if let val = value(for: index) {
                    Text(val)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .transition(.blurReplace)
                }
            }
    }
    
    private func borderColour(index: Int) -> Color {
        switch state {
        case .typing: value.count == 6 && isActive ? Color.primary : .gray
        case .invalid: .red
        case .valid: .green
        }
    }
    
    private func value(for index: Int) -> String? {
        if value.count > index {
            let startIndex = value.startIndex
            let stringIndex = value.index(startIndex, offsetBy: index)
            
            return String(value[stringIndex])
        }
        
        return nil
    }
}

#Preview {
    @Previewable @State var text: String = "ABC123"
    
    OTPPassView(value: $text) { val in
        if val == "111111" {
            return .valid
        } else if val.count == 6 {
            return .invalid
        } else {
            return .typing
        }
    }
}
