//
//  WiFiManager.swift
//  iTello
//
//  Created by Michael Ellis on 11/14/21.
//

import Foundation

public protocol WiFiManager: ObservableObject {
    var isConnectedToWiFi: Bool { get set }
}
