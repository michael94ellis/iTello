//
//  WiFiManagement.swift
//  iTello
//
//  Created by Michael Ellis on 12/10/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

struct WiFiManagement: View {
    
    @Binding var displayPopover: Bool
    @State var errorMessage: String?
    @State var progress = 0.0
    @ObservedObject var wifiManager = WifiManager.shared
    
    var body: some View {
        Text(errorMessage ?? "")
            .font(.callout)
            .foregroundColor(Color.red)
            .frame(height: 25)
        Button(action: {
            WifiManager.shared.connect { success, error in
                if let error = error {
                    self.errorMessage = error
                } else {
                    self.displayPopover.toggle()
                }
            }
        }, label: {
            if WifiManager.shared.connectionProgress != 0 {
                ProgressView("Connecting...", value: self.progress, total: 4)
                    .onReceive(WifiManager.shared.$connectionProgress, perform: { progressValue in
                        self.progress = progressValue
                    })
                    .frame(width: 220, height: 40)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .shadow(color: .darkEnd, radius: 2, x: 1, y: 2)
                    .frame(width: 200, height: 40)
                    .overlay(
                        HStack {
                            Image(systemName: "wifi")
                            if WifiManager.shared.isConnectedToWiFi {
                                Text("Reconnect").foregroundColor(Color.darkEnd)
                            } else {
                                Text("Connect").foregroundColor(Color.darkEnd)
                            }
                        })
            }
        })
    }
}
