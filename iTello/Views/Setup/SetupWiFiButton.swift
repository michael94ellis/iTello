//
//  SetupWiFiButton.swift
//  iTello
//
//  Created by Michael Ellis on 12/10/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

struct SetupWiFiButton: View {
    
    @Binding var displayPopover: Bool
    @State var errorMessage: String?
    @State var progress = 0.0
    @ObservedObject var wifiManager = WifiManager.shared
    
    var body: some View {
        VStack {
            Text(errorMessage ?? "")
                .font(.callout)
                .foregroundColor(Color.red)
                .frame(height: 25)
            Spacer()
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
                        .progressViewStyle(CircularProgressViewStyle(tint: .telloSilver))
                        .onReceive(WifiManager.shared.$connectionProgress, perform: { progressValue in
                            self.progress = progressValue
                        })
                        .frame(width: 220, height: 40)
                } else {
                    HStack {
                        Image(systemName: "wifi").foregroundColor(Color.telloDark)
                        if WifiManager.shared.isConnected {
                            if let ssid = WifiManager.shared.telloSSID {
                                Text(ssid)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.telloDark)
                            } else {
                                Text("Reconnect")
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.telloDark)
                            }
                        } else {
                            Text("Connect")
                                .fontWeight(.semibold)
                                .foregroundColor(Color.telloDark)
                        }
                    }
                    .foregroundColor(Color.white)
                    .frame(width: 300, height: 100)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.telloSilver))
                }
            })
            Spacer()
        }
    }
}
