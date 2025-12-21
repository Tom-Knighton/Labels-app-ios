//
//  JoinHomePage.swift
//  Tomja
//
//  Created by Tom Knighton on 21/12/2025.
//

import SwiftUI

struct JoinHomePage: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var otp: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.color1.ignoresSafeArea()
                
                VStack {
                    Text("Join a Home")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer().frame(height: 12)
                    Text("Enter the 6-digit code of the home you wish to join below")
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                    Spacer()
                    
                    OTPPassView(value: $otp) { val in
                        if val == "111111" {
                            return .valid
                        } else if val.count == 6 {
                            return .invalid
                        } else {
                            return .typing
                        }
                    }
                    
                    
                    Spacer()
                    Spacer()

                    Button(action: {}) {
                        Text("Join")
                            .font(.title3.bold())
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonPlatformProminent()
                    .disabled(otp.count != 6)
                }
                .scenePadding()
            }
            .fontDesign(.rounded)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { self.dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        
    }
}

#Preview {
    JoinHomePage()
}
