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

import Photos

@main
struct iTelloApp: App {
    
    @StateObject private var telloStore: TelloStoreViewModel = TelloStoreViewModel()
    @StateObject private var tello: TelloController = TelloController()
    @State private var displayAppSettings: Bool = true
    
    var wifiConnectionListener: AnyCancellable?
    var droneConnectionListener: AnyCancellable?
    
    // TODO: Tab View for help page, settings pages, and connection page
    
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
                if displayAppSettings {
                    AppSettings(telloStore: self.telloStore, isDisplayed: self.$displayAppSettings)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                        .background(LinearGradient(.darkEnd, .darkStart, .darkStart, .darkEnd))
                        .onReceive(self.tello.$commandable.receive(on: DispatchQueue.main), perform: { [self] commandable in
                            // Listen for successful command mode initialization and then remove the setup popover
                            self.displayAppSettings = !commandable
                        })
                }
            }
            .environmentObject(telloStore)
        }
    }
}
