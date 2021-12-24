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

public var theurl: URL?

@main
struct iTelloApp: App {
    
    @StateObject private var tello: TelloController = TelloController()
    @State private var displayAppSettings: Bool = true
    
    var wifiConnectionListener: AnyCancellable?
    var droneConnectionListener: AnyCancellable?
    
    // TODO: Tab View for help page, settings pages, and connection page
    
    init() {
        FirebaseApp.configure()
        
        PHPhotoLibrary.requestAuthorization { authStatus in
            if authStatus != .authorized {
                print(authStatus)
                // TODO: Handle this error
            }
            
            
            let fileManager = FileManager.default
            
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
                fileURLs.forEach {
//                    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum($0.path)) {
//                        UISaveVideoAtPathToSavedPhotosAlbum($0.path, nil, nil, nil)
//                    }
                    theurl = $0
                }
            } catch {
                print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
            }
        }
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
                    AppSettings(isDisplayed: self.$displayAppSettings)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                        .background(LinearGradient(.darkEnd, .darkStart, .darkStart, .darkEnd))
                        .onReceive(self.tello.$commandable.receive(on: DispatchQueue.main), perform: { [self] commandable in
                            // Listen for successful command mode initialization and then remove the setup popover
                            self.displayAppSettings = !commandable
                        })
                }
            }
        }
    }
}
