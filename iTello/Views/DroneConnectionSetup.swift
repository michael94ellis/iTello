//
//  AppOnboarding.swift
//  iTello
//
//  Created by Michael Ellis on 12/7/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

struct DroneConnectionSetup: View {
    
    @Binding var isDisplayed: Bool
    private let screenCoverage: CGFloat = 0.9
    @FocusState var wifiTextFieldFocus: Bool

    var body: some View {
        GeometryReader { parent in
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Text("Welcome to iTello!")
                    WiFiAndSettingsHelp()
                    WiFiManagement()
                    Spacer()
                    Button(action: {
                        self.isDisplayed.toggle()
                    }, label: {
                        Text("Continue")
                            .frame(width: 120, height: 40)
                    })
                    .contentShape(Rectangle())
                    Spacer()
                }
                Spacer()
            }
            .background(Rectangle()
                            .fill(RadialGradient(colors: [.white, .gray], center: .center, startRadius: 1, endRadius: parent.size.width * 0.95))
                            .shadow(color: .darkEnd, radius: 3, x: 1, y: 2))
        }
    }
}
