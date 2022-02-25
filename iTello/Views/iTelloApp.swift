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
    
    @StateObject private var tello: TelloController = TelloController()
    @State private var displayAppSettings: Bool = true
    @State private var displayMediaGallery: Bool = false
    
    var wifiConnectionListener: AnyCancellable?
    var droneConnectionListener: AnyCancellable?
        
    init() {
        FirebaseApp.configure()
        
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white  as Any], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(named: "TelloLight") as Any], for: .normal)
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.lightGray
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .center) {
                DroneController(tello: self.tello, displaySettings: self.$displayAppSettings)
                    .background(LinearGradient(.darkEnd, .darkStart, .darkStart, .darkEnd))
                    .onReceive(WifiManager.shared.$isConnected, perform: { [self] isConectedToWiFi in
                        print("WiFi Connection: \(isConectedToWiFi)")
                        // Listen for announcement of WiFi connection and then initiate command mode async
                        if isConectedToWiFi {
                            self.tello.beginCommandMode()
                        } else {
                            self.tello.exitCommandMode()
                        }
                    })
                if displayAppSettings {
                    AppSettings(tello: self.tello, isDisplayed: self.$displayAppSettings, mediaGalleryDisplayed: self.$displayMediaGallery)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                        .background(LinearGradient(.darkEnd, .darkStart, .darkStart, .darkEnd)
                                        .onTapGesture{ self.displayAppSettings.toggle() })
                        .edgesIgnoringSafeArea(.all)
                }
                if displayMediaGallery {
                    MediaGallery(displayMediaGallery: self.$displayMediaGallery)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(LinearGradient(.darkEnd, .darkStart, .darkStart, .darkEnd))
                }
            }
        }
    }
}
