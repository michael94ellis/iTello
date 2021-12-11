//
//  iTelloApp.swift
//  iTello
//
//  Created by Michael Ellis on 11/14/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

@main
struct iTelloApp: App {
    
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    
    @StateObject var tello = TelloController()
    @State private var displayConnectionSetup: Bool = true
    @AppStorage("displaySettings") var displaySettings: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .center) {
                if displayConnectionSetup {
                    DroneConnectionSetup(isDisplayed: $displayConnectionSetup)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .zIndex(3)
                }
                if displaySettings {
                    ControllerSettings(isDisplayed: $displaySettings)
                        .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                        .zIndex(2)
                }
                DroneController(displaySettings: $displaySettings)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
