//
//  WiFiAndSettingsHelpView.swift
//  iTello
//
//  Created by Michael Ellis on 12/10/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

struct WiFiAndSettingsHelp: View {
    
    @State var displayPopover: Bool = false
    @State var errorMessage: String?
    
    /// Open iOS Device Settings
    func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                if !success {
                    self.errorMessage = "Settings didn't open, please try again or go to the Settings app manually"
                } else {
                    displayPopover.toggle()
                }
            })
        }
    }
    
    var body: some View {
        Button(action: { self.displayPopover.toggle() }) {
            Text("Don't know the WiFi Name?")
                .fontWeight(.semibold)
                
        }
        .buttonStyle(BorderlessButtonStyle())
        .popover(isPresented: self.$displayPopover, content: {
            Text("If your Tello is on and blinking yellow you can find the WiFi name in the list of WiFi networks. It will start with \"Tello-\"")
                .lineLimit(2)
            Button(action: {self.openSettings) {
                Text("Open Settings").fontWeight(.semibold)
            }
        })
    }
}
