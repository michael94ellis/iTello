//
//  HelpPopover.swift
//  iTello
//
//  Created by Michael Ellis on 12/10/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

struct HelpPopover: View {
    
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
            VStack(alignment: .leading) {
                Text("1. Turn on your Tello and wait for a blinking yellow light.")
                Text("2. Press the Connect button, the app will find your Tello")
                Text("3. When the controller is displayed you can begin flying!")
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
            }
            .padding(40)
        })
    }
}
