//
//  MacWiFiManager.swift
//  iTello
//
//  Created by Michael Ellis on 11/14/21.
//

import CoreWLAN
import Network
import SwiftUI

class MacWifiManager: WiFiManager, ObservableObject {
    
    // Remember the users WiFi name between sessions
    private static let telloSSIDKey = "SSID"
    @AppStorage(telloSSIDKey) var telloSSID: String = "TELLO-"
    @Published public var isConnectedToWiFi: Bool = false
    
    private let networkStatusMonitor = NWPathMonitor()
    
    /// The Single accessor of the MacOS WiFi Manager
    static var shared = MacWifiManager()
    /// Must use the Self.shared accessor
    private init() {
        networkStatusMonitor.pathUpdateHandler = { networkPath in
            self.isConnectedToWiFi = networkPath.status == .satisfied
        }
    }
    deinit { }
    
    func connectTo(ssid: String, completion: @escaping (Bool) -> ()) {
            print("Error: Attempt to connect to Tello SSID Failed: \(#function)")
    }
    
}
