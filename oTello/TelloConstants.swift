//
//  CommandStrings.swift
//  oTello
//
//  Created by Michael Ellis on 5/21/20.
//  Copyright © 2020 Mellis. All rights reserved.
//
/// Networking Information about the DJI Tello
struct Tello {
    /// IP Address the Tello receives UDP messages on
    static let IPAddress = "192.168.10.1"
    /// IP Address the Tello sends UDP messages on
    static let ResponseIPAddress = "0.0.0.0"
    /// Port the Tello receives UDP messages on
    static let CommandPort: Int32 = 8889
    /// Port the Tello sends UDP messages on
    static let StatePort: Int32 = 8890
    /// Port the Tello sends UDP Video Stream Data on
    static let VideoStreamPort: Int32 = 11111
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

