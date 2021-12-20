//
//  SetupMenu.swift
//  iTello
//
//  Created by Michael Ellis on 12/7/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

struct SetupMenu: View {
    
    @Binding var isDisplayed: Bool
    @Binding var displaySettings: Bool
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer(minLength: 30)
            Text("iTello")
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .font(.largeTitle)
            VStack {
                SetupWiFiButton(displayPopover: $isDisplayed)
                    .padding(.bottom, 15)
                HStack {
                    SetupInstructions()
                    Button(action: {
                        self.isDisplayed.toggle()
                        self.displaySettings.toggle()
                    }, label: {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .shadow(color: .darkEnd, radius: 2, x: 1, y: 2)
                            .frame(width: 200, height: 40)
                            .overlay(
                                HStack {
                                    Image(systemName: "gear")
                                    Text("Settings").foregroundColor(Color.darkEnd)
                                })
                    })
                }
            }
            // TODO: Feature Idea - user can connect on their own
            Spacer()
            Button(action: { self.isDisplayed.toggle() }) {
                Text("Already Connected?")
                    .fontWeight(.semibold)
                    .frame(width: 200, height: 40)
            }
            .contentShape(Rectangle())
            Spacer(minLength: 30)
        }
    }
}
