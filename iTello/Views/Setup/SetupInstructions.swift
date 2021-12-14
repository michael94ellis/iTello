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
    
    var body: some View {
        Button(action: { self.displayPopover.toggle() }) {
            Text("Don't know what to do?")
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
            Text("Connect to the Tello's WiFi or let the app do it for you")
                Divider()
                Group {
                    Text("1. Turn on your Tello and wait for a blinking yellow light.")
                    Text("2. Press the Connect button, the app will find your Tello")
                    Text("3. When the controller is displayed you can begin flying!")
                    Text("4. Provide feedback and feature requests by leaving a review on the App Store!")
                }
                Divider()
                HStack {
                    Spacer()
                    Button(action: {
                        if let url = URL(string: "itms-apps://apple.com/app/id839686104") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Go to App Store")
                            .fontWeight(.semibold)
                            .foregroundColor(Color.mint)
                    }
                    .frame(width: 130, height: 40)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray).shadow(color: Color(UIColor.label), radius: 4, x: 2, y: 2))
                    .contentShape(Rectangle())
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { self.displayPopover.toggle() }) {
                        Text("Dismiss")
                            .fontWeight(.semibold)
                            .foregroundColor(Color.mint)
                    }
                    .frame(width: 130, height: 40)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray).shadow(color: Color(UIColor.label), radius: 4, x: 2, y: 2))
                    .contentShape(Rectangle())
                    Spacer()
                }
                Spacer()
            }
            .padding(40)
        })
    }
}
