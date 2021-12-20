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
    @State private var displayAppSettings: Bool = false
    
    var wifiConnectionListener: AnyCancellable?
    var droneConnectionListener: AnyCancellable?
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .center) {
                DroneController(tello: self.tello, displaySettings: self.$displayAppSettings)
                    .onReceive(WifiManager.shared.$isConnected, perform: { [self] isConectedToWiFi in
                        print("WiFi Connection: \(isConectedToWiFi)")
                        // Listen for announcement of WiFi connection and then initiate command mode async
                        if isConectedToWiFi,
                           !self.tello.connected {
                            self.tello.beginCommandMode()
                        }
                    })
                if displayConnectionSetup {
                    SetupMenu(isDisplayed: self.$displayConnectionSetup, displaySettings: self.$displayAppSettings)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                        .background(LinearGradient(.darkEnd, .darkStart, .darkStart, .darkEnd))
                        .onReceive(self.tello.$commandable, perform: { [self] commandable in
                            // Listen for successful command mode initialization and then remove the setup popover
                            self.displayConnectionSetup = !commandable
                        })
                }
                if displayAppSettings {
                    AppSettings(isDisplayed: self.$displayAppSettings, setupConnectionDisplayed: self.$displayConnectionSetup)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                        .background(LinearGradient(.darkEnd, .darkStart, .darkStart, .darkEnd))
                        .onReceive(self.tello.$commandable, perform: { [self] commandable in
                            // Listen for successful command mode initialization and then remove the setup popover
                            self.displayConnectionSetup = !commandable
                        })
                }
            }
        }
    }
}
