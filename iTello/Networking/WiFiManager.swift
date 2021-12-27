//
//  WifiManager.swift
//  iTello
//
//  Created by Michael Ellis on 5/19/20.
//  Copyright © 2020 Mellis. All rights reserved.
//

import SwiftUI
import Network
import NetworkExtension


final public class WifiManager: ObservableObject {
    
    @Published public var isConnected: Bool = false
    @Published public var telloSSID: String?
    @Published public var connectionProgress: Double = 0
    /// Only one WiFi connection is permitted at a time so all access must be through the `static shared instance`
    static var shared = WifiManager()
    // Prevent anyone from instantiating their own `WifiManager`
    private init() { }
    
    deinit {
        self.removeCurrentConfiguration()
    }
    
    func removeCurrentConfiguration() {
        if let telloSSID = self.telloSSID {
            NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: telloSSID)
        }
    }
    
    func connect(completion: @escaping (_ success: Bool, _ error: String?) -> ()) {
        self.connectionProgress += 1
        let newHotspotConfig = NEHotspotConfiguration(ssidPrefix: "TELLO-")
        self.removeCurrentConfiguration()
        self.connectionProgress += 1
        NEHotspotConfigurationManager.shared.apply(newHotspotConfig) { error in
            self.connectionProgress += 1
            if let errorString = self.handleConnectionError(error) {
                self.connectionProgress = 0
                self.isConnected = false
                DispatchQueue.main.async {
                    completion(false, errorString)
                }
            } else {
                NEHotspotConfigurationManager.shared.getConfiguredSSIDs(completionHandler: {
                    self.connectionProgress += 1
                    if let telloSSID = $0.first {
                        // Bugfix Attempt: seems like UDP Clients are created too early
                        DispatchQueue.main.async {
                            usleep(250000) // will sleep for 0.25 seconds
                            self.telloSSID = telloSSID
                            // Tells UDP Clients they can now communicate via wifi
                            self.isConnected = true
                            self.connectionProgress = 0
                            completion(true, nil)
                        }
                    }
                })
            }
        }
    }
    
    /// Return Human Readable String that explains what went wrong
    private func handleConnectionError(_ error: Error?) -> String? {
        self.connectionProgress = 0
        self.isConnected = false
        guard let error = error else {
            return nil
        }
        let nsError = error as NSError
        if nsError.domain == "NEHotspotConfigurationErrorDomain" {
            if let configError = NEHotspotConfigurationError(rawValue: nsError.code) {
                switch configError {
                case .invalidWPAPassphrase:
                    return "Invalid Password"
                case .invalidSSID:
                    return "Invalid SSID"
                case .invalidSSIDPrefix:
                    return "Invlaid SSID Prefix"
                case .invalid,
                        .invalidWEPPassphrase,
                        .invalidEAPSettings,
                        .invalidHS20Settings,
                        .invalidHS20DomainName,
                        .pending,
                        .systemConfiguration,
                        .joinOnceNotSupported,
                        .alreadyAssociated,
                        .applicationIsNotInForeground,
                        .internal:
                    return "Connection Error - \(configError.rawValue)"
                case .userDenied:
                    return "Permission denied by User"
                case .unknown:
                    return "Could not find Tello WiFi"
                @unknown default:
                    return "Unknown Error"
                }
            }
        }
        return "Unknown Error"
    }
    
}
