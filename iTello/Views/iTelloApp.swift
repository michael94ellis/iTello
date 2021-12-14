//
//  iTelloApp.swift
//  iTello
//
//  Created by Michael Ellis on 11/14/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI
import Combine

@main
struct iTelloApp: App {
    
    @State private var tello: TelloController?
    @State private var displayConnectionSetup: Bool = true
    
    var wifiConnectionListener: AnyCancellable?
    
    init() {
        // Listen for announcement of WiFi connection
        self.wifiConnectionListener = WifiManager.shared.$isConnectedToWiFi.sink(receiveValue: { [self] isConectedToWiFi in
            print("WiFi Connection: \(isConectedToWiFi)")
            if isConectedToWiFi, tello == nil {
                self.tello = TelloController()
            } else if !isConectedToWiFi {
                self.tello = nil
                self.displayConnectionSetup = true
            }
        })
    }
    
    var body: some Scene {
        WindowGroup {
            GeometryReader { container in
                ZStack(alignment: .center) {
                    DroneController(tello: self.$tello, displaySettings: $displayConnectionSetup)
                    if displayConnectionSetup {
                        DroneConnectionSetup(isDisplayed: $displayConnectionSetup)
                            .frame(width: container.size.width, height: container.size.height)
                            .background(Rectangle()
                                            .fill(RadialGradient(colors: [.white, .gray, .darkStart, .darkEnd, .gray], center: .center, startRadius: 1, endRadius: 1600))
                                            .shadow(color: .darkEnd, radius: 3, x: 1, y: 2))
                    }
                }
                .background(.white)
            }
        }
    }
}
