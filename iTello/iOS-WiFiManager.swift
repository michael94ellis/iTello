//
//  MobileWifiManager.swift
//  iTello
//
//  Created by Michael Ellis on 5/19/20.
//  Copyright © 2020 Mellis. All rights reserved.
//

import SwiftUI
import Network
import NetworkExtension

final public class MobileWifiManager: WiFiManager, ObservableObject {
    
    // Remember the users WiFi name between sessions
    private static let telloSSIDKey = "SSID"
    @AppStorage(telloSSIDKey) var telloSSID: String = "TELLO-"
    @Published public var isConnectedToWiFi: Bool = false
    
    private let networkStatusMonitor = NWPathMonitor()
    private var hotspotConfig: NEHotspotConfiguration?

    static var shared = MobileWifiManager()
    private init() {
        networkStatusMonitor.pathUpdateHandler = { networkPath in
            self.isConnectedToWiFi = networkPath.status == .satisfied
        }
    }
    deinit {
        NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: self.telloSSID)
    }
    
    func connect(completion: @escaping (Bool) -> ()) {
        let newHotspotConfig = NEHotspotConfiguration(ssid: self.telloSSID)
        self.hotspotConfig = newHotspotConfig
        newHotspotConfig.joinOnce = true
        NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: self.telloSSID)
        NEHotspotConfigurationManager.shared.apply(newHotspotConfig) { [weak self] (error) in
            // Capture reference to [weak self]
            guard let self = self else { return }
            if let error = error {
                print(self.handleConnectionError(error))
            }
            completion(self.isConnectedToWiFi)
        }
    }
    
    /// Return Human Readable String that explains what went wrong
    private func handleConnectionError(_ error: Error) -> String {
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
                        .userDenied,
                        .pending,
                        .systemConfiguration,
                        .unknown,
                        .joinOnceNotSupported,
                        .alreadyAssociated,
                        .applicationIsNotInForeground,
                        .internal:
                    return "Connection Error"
                @unknown default:
                    return "Unknown Error"
                }
            }
        }
        return "Unknown Error"
    }
}
