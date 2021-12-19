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
    
    private let openButtonText: String = "Don't know what to do?"
    private let title: String = "How To Connect Your Tello"
    
    private let appStoreUrl: String = "itms-apps://apple.com/app/id839686104"
    
    private let reviewButtonText: String = "Send Logs"
    private let dismissButtonText: String = "Dismiss"

    private let instructions: [String] = [
        "1. Turn on your Tello and wait for a blinking yellow light.",
        "2. Press the Connect button, the app will find your Tello!",
        "3. When the controller is displayed you can begin flying",
        "4. Leave a great review on the App Store!"
    ]
    
    var body: some View {
        Button(action: { self.displayPopover.toggle() }) {
            Text(self.openButtonText)
                .fontWeight(.semibold)
                .foregroundColor(Color(UIColor.label))
        }
        .frame(width: 200, height: 40)
        .background(RoundedRectangle(cornerRadius: 4)
                        .fill(Color(UIColor.lightGray))
                        .shadow(color: Color.darkStart, radius: 2, x: 1, y: 2))
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
                .background(RoundedRectangle(cornerRadius: 4).fill(Color(uiColor: .tertiarySystemBackground)))
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
//                        if let url = URL(string: self.appStoreUrl) {
//                            UIApplication.shared.open(url)
//                        }
                        sendLogs()
                    }) {
                        Text(self.reviewButtonText)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(uiColor: .label))
                    }
                    .frame(width: 150, height: 40)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray).shadow(color: Color(uiColor: .lightGray), radius: 1, x: 0, y: 0))
                    .contentShape(Rectangle())
                    Spacer()
                    Button(action: { self.displayPopover.toggle() }) {
                        Text(self.dismissButtonText)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(uiColor: .label))
                    }
                    .frame(width: 150, height: 40)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray))
                    .contentShape(Rectangle())
                    Spacer()
                }
                Spacer()
            }
            .padding(40)
        })
    }
}
