//
//  LandingPage.swift
//  Tomja
//
//  Created by Tom Knighton on 21/12/2025.
//

import SwiftUI
import SwiftData

struct LandingPage: View {
    
    @Environment(\.modelContext) private var context
    @State private var showJoinPage: Bool = false
    @State private var showCreatePage: Bool = false
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
                Button(action: { self.showCreatePage.toggle() }) {
                    Text("Create a Home")
                        .font(.title3.bold())
                        .padding(6)
                        .frame(maxWidth: .infinity)
                }
                .buttonPlatformProminent()
                
                Button(action: { self.showJoinPage.toggle() }) {
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
        .sheet(isPresented: $showJoinPage) {
            JoinHomePage()
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showCreatePage) {
            CreateHomePage()
                .interactiveDismissDisabled()
        }
    }
}

#Preview {
    LandingPage()
}
