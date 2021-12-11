//
//  WiFiManagementView.swift
//  iTello
//
//  Created by Michael Ellis on 12/10/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

struct WiFiManagement: View {
    var body: some View {
        HStack {
            Text("Tello WiFi Name: ")
                .padding(3)
            TextField("WiFi Name(SSID)", text: WifiManager.shared.$telloSSID, prompt: Text("Tello-A1BC23"))
                .padding(3)
                .background(RoundedRectangle(cornerRadius: 16).fill(.clear).border(Color.darkEnd))
                .frame(width: 120)
                .padding(.bottom, 10)
        }
        Button(action: {
            WifiManager.shared.connect { success, error in
                if success {
                    // TODO: Handle WiFi Connection Success
                } else {
                    // TODO: Handle WiFi Connection Error
                }
            }
        }, label: {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.green)
                .shadow(color: .darkEnd, radius: 2, x: 1, y: 2)
                .frame(width: 120, height: 40)
                .overlay(
                    HStack {
                        Image(systemName: "wifi")
                        Text("Connect").foregroundColor(Color.darkEnd)
                    })
        })
    }
}
