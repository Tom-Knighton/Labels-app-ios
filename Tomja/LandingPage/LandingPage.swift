//
//  LandingPage.swift
//  Tomja
//
//  Created by Tom Knighton on 21/12/2025.
//

import SwiftUI

struct LandingPage: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            Color.color1.ignoresSafeArea()
            VStack {
                Spacer()
                Image(colorScheme == .dark ? "AppIconDisplayDark" : "AppIconDisplayLight")
                    .resizable()
                    .frame(width: 200, height: 200)
                
                Text("TomJa")
                    .font(.largeTitle.bold())
                Text("Create or join a home below to start sending lovely messages :)")
                    .multilineTextAlignment(.center)
                Spacer()
                Spacer()
                Button(action: {}) {
                    Text("Create a Home")
                        .font(.title3.bold())
                        .padding(6)
                        .frame(maxWidth: .infinity)
                }
                .buttonPlatformProminent()
                
                Button(action: {}) {
                    Text("Join a Home")
                        .font(.title3.bold())
                        .padding(6)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.foreground)
                }
                .buttonPlatformBordered()
            }
            .scenePadding()
            .fontDesign(.rounded)
        }
    }
}

#Preview {
    LandingPage()
}
