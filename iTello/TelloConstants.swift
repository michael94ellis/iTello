//
//  CommandStrings.swift
//  iTello
//
//  Created by Michael Ellis on 5/21/20.
//  Copyright © 2020 Mellis. All rights reserved.
//

import Foundation
import Network

/// Networking Information about the DJI Tello
struct Tello {
    /// IP Address the Tello receives UDP messages on
    static let IPAddress = "192.168.10.1"
    /// IP Address the Tello sends UDP messages on
    static let ResponseIPAddress = "0.0.0.0"
    /// Port the Tello receives UDP messages on
    static let CommandPort: NWEndpoint.Port = 8889
    /// Port the Tello sends UDP messages on
    static let StatePort: NWEndpoint.Port = 8890
    /// Port the Tello sends UDP Video Stream Data on
    static let VideoStreamPort: NWEndpoint.Port = 11111
}

/// Networking Information about the DJI Tello
struct TelloSettings {
    static private let isCameraOnKey = "CameraKey"
    static var isCameraOn: Bool {
        get { UserDefaults.standard.bool(forKey: isCameraOnKey) }
        set { UserDefaults.standard.set(newValue, forKey: isCameraOnKey) }
    }
    static private let showCameraAndVideoButtons = "ShowCameraVideoKey"
    static var isShowingRecordingButtons: Bool {
        get { UserDefaults.standard.bool(forKey: showCameraAndVideoButtons) }
        set { UserDefaults.standard.set(newValue, forKey: showCameraAndVideoButtons) }
    }
    static private let speedBoostKey = "SpeedBoostKey"
    static var speedBoost: Int {
        get { UserDefaults.standard.integer(forKey: speedBoostKey) }
        set { UserDefaults.standard.set(newValue, forKey: speedBoostKey) }
    }
    static private let showFlipsKey = "ShowFlipsKey"
    static var showFlips: Bool {
        get { UserDefaults.standard.bool(forKey: showFlipsKey) }
        set { UserDefaults.standard.set(newValue, forKey: showFlipsKey) }
    }
    static private let invertJoySticksKey = "InvertJoySticks"
    static var invertedJoySticks: Bool {
        get { UserDefaults.standard.bool(forKey: invertJoySticksKey) }
        set { UserDefaults.standard.set(newValue, forKey: invertJoySticksKey) }
    }
}
struct CMD {
    /// Tells the drone to enter Commandable Mode, where it will listen to these commands
    static let on = "command"
    /// Drone attempts to takeoff and stabilize itself, needs a few seconds before it can land
    static let takeOff = "takeoff"
    /// Causes the drone to attempt to lower itself to a surface so it can power down the motors
    static let land = "land"
    /// Causes the drone to hover
    static let hover = "stop"
    /// Immediately stops the drone
    static let off = "emergency"
    /// Begin streaming video
    static let streamOn = "streamon"
    /// End streaming video
    static let streamOff = "streamoff"
}
enum FLIP: String {
    /// Flip left
    case l
    /// Flip right
    case r
    /// Flip forward
    case f
    /// Flip backward
    case b
    /// returns the tello command for a flip
    var commandValue: String {
        "flip \(self.rawValue)"
    }
}

