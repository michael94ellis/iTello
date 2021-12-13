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
        VStack(spacing: 25) {
            Spacer(minLength: 30)
            Text("iTello")
                .foregroundColor(Color.black)
                .fontWeight(.semibold)
                .font(.largeTitle)
            WiFiManagement(displayPopover: $isDisplayed)
            HelpPopover()
            Button(action: { self.isDisplayed.toggle() }) {
                Text("Already Connected?")
                    .fontWeight(.semibold)
                    .foregroundColor(Color(UIColor.label))
                    .frame(width: 200, height: 40)
            }
            .contentShape(Rectangle())
            Spacer(minLength: 30)
        }
    }
}
