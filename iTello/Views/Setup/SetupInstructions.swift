//
//  SetupInstructions.swift
//  iTello
//
//  Created by Michael Ellis on 12/10/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

struct SetupInstructions: View {
    
    @State var displayPopover: Bool = false
    @State var errorMessage: String?
    
    private let openButtonText: String = "Need Help?"
    private let title: String = "How To Connect Your Tello"
    
    private let appStoreUrl: String = "itms-apps://apple.com/app/id839686104"
    
    private let reviewButtonText: String = "Send Logs"
    private let dismissButtonText: String = "Dismiss"

    private let instructions: [String] = [
        "1. Turn on your Tello and wait for a blinking yellow light.",
        "2. Press the Connect button, the app will find your Tello!",
        "3. When the controller is displayed you can begin flying",
        "4. Photos will save to your photo gallery",
        "5. Leave a great review on the App Store!"
    ]
    
    var body: some View {
        Button(action: { self.displayPopover.toggle() }) {
            Text(self.openButtonText)
                .fontWeight(.semibold)
                .foregroundColor(Color.white)
                .frame(width: 300, height: 80)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray))
        }
        .contentShape(Rectangle())
        .popover(isPresented: self.$displayPopover, content: {
            VStack(alignment: .center) {
                Text(self.title)
                    .font(.largeTitle)
                Divider()
                VStack(alignment: .leading) {
                    ForEach(self.instructions, id: \.self) {
                        Text($0)
                            .padding(.bottom, 5)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 20)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(uiColor: .tertiarySystemBackground)))
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { self.displayPopover.toggle() }) {
                        Text(self.dismissButtonText)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.white)
                            .frame(width: 200, height: 60)
                    }
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(uiColor: .gray)))
                    .contentShape(Rectangle())
                    Spacer()
                }
                Spacer()
            }
            .padding(40)
        })
    }
}
