//
//  iTelloApp.swift
//  iTello
//
//  Created by Michael Ellis on 11/14/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI
import Combine
import Firebase

@main
struct iTelloApp: App {
    
    @StateObject private var tello: TelloController = TelloController()
    @State private var displayConnectionSetup: Bool = true
    
    var wifiConnectionListener: AnyCancellable?
    var droneConnectionListener: AnyCancellable?
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            GeometryReader { container in
                ZStack(alignment: .center) {
                    DroneController(tello: self.tello, displaySettings: $displayConnectionSetup)
                        .onReceive(WifiManager.shared.$isConnected, perform: { [self] isConectedToWiFi in
                            print("WiFi Connection: \(isConectedToWiFi)")
                            // Listen for announcement of WiFi connection and then initiate command mode async
                            if isConectedToWiFi,
                               !self.tello.connected {
                                self.tello.beginCommandMode()
                            }
                        })
                    if displayConnectionSetup {
                        DroneConnectionSetup(isDisplayed: $displayConnectionSetup)
                            .frame(width: container.size.width, height: container.size.height)
                            .background(Rectangle()
                                            .fill(RadialGradient(colors: [.white, .gray, .darkStart, .darkEnd, .gray], center: .center, startRadius: 1, endRadius: 1600))
                                            .shadow(color: .darkEnd, radius: 3, x: 1, y: 2))
                            .onReceive(self.tello.$commandable, perform: { [self] commandable in
                                // Listen for successful command mode initialization and then remove the setup popover
                                self.displayConnectionSetup = !commandable
                            })
                    }
                }
                .background(.white)
            }
        }
    }
}
