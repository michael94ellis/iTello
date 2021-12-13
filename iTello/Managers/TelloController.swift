//
//  TelloController.swift
//  iTello
//
//  Swift Class to interact with the DJI/Ryze Tello drone using the official Tello api.
//  Tello API documentation:
//  https://dl-cdn.ryzerobotics.com/downloads/tello/20180910/Tello%20SDK%20Documentation%20EN_1.3.pdf
//

import Foundation

protocol TelloAVDelegate: AnyObject {
    func sendCommand(_ command: String)
}

/// This Swift object can control a DJI Tello drone and also decode and display it's video stream
class TelloController: TelloAVDelegate, ObservableObject {
    /// Indicates whether or not the drone has been put into command mode
    @Published private(set) var commandable = false
    /// Amount of time between each movement broadcast to prevent getting spam-bocked by the drone
    private let commandDelay = 0.1
    /// Speed of Up/Down movement
    var upDown = 0
    /// Speed of Left/Right movement
    var leftRight = 0
    /// Speed of Forward/Back movement
    var forwardBack = 0
    /// Speed of movement Clockwise or CounterClockwise
    var yaw = 0
    /// rc l/r f/b u/d yaw
    private var moveCommand: String { "rc \(self.leftRight) \(self.forwardBack) \(self.upDown) \(self.yaw)" }
    /// Prevents too many movement commands from being issued at once
    // TODO: Timer to send a message(CMD.on) after every 4 second the user hasn't sent a command to keep the drone active
    
    // MARK: - Stream Data Vars
    
    private var responseWaiter = Timer()
    /// Last known battery amount received from tello
    var battery = ""
    /// Last known Signal to Noise ratio for WiFi received from tello
    var wifi = ""
    
    // UDP Connections
    var stateClient = UDPClient(address: Tello.ResponseIPAddress, port: Tello.StatePort)
    var commandClient = UDPClient(address: Tello.IPAddress, port: Tello.CommandPort)
    
    let avManager = AVManager()
    
    static var shared: TelloController?
    
    /// The TelloController will spawn 2 threads immediately, on each thread will be on of the two UDP objects above
    ///     A receiving/listener for both Drone State and Command Responsesf
    init() {
        self.avManager.avDelegate = self
        self.commandClient?.messageReceived = self.handleCommandResponse(message:)
        self.stateClient?.messageReceived = self.handleStateStream(data:)
        self.stateClient?.setupListener()
        self.commandClient?.setupConnection()
        self.repeatCommandForResponse()
    }
    
    /// This var will decrease as the initial command is sent multiple times
    private var commandRepeatMax = 4
    /// Repeats a comment until an `ok` is received from the Tello
    private func repeatCommandForResponse() {
        self.responseWaiter = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            if !self.commandable, self.commandRepeatMax > 0 {
                self.sendCommand(CMD.on)
                self.commandRepeatMax -= 1
            } else {
                self.responseWaiter.invalidate()
                self.commandRepeatMax = 4
            }
        }
    }

    // MARK: - Tello Command Methods
    
    func takeOff() {
        sendCommand(CMD.takeOff)
    }
    /// Can sometimes be ignored, especially if within first 5 seconds or so of flight time
    func land() {
        sendCommand(CMD.land)
    }
    /// EMERGENCY STOP, drone motors will cease immediately, should not always be viasible to user
    func emergencyLand() {
        sendCommand(CMD.off)
    }
    /// See the FLIP enum for list of available flip directions
    func flip(_ direction: FLIP) {
        sendCommand(direction.commandValue)
    }
    
    /// Handles continuous movement events from the Joysticks, limiting output commands to once per `commandDelay`
    func updateMovementTimer() {
//        if moveTimer.isValid { return }
//        moveTimer = Timer.scheduledTimer(withTimeInterval: commandDelay, repeats: true) { _ in
            // Concatenate the 4 int values and compare to 0 using bitwise operator AND(&)
            if self.leftRight & self.forwardBack & self.upDown & self.yaw == 0 {
                // The joysticks go back to 0 when the user lets go, therefore if the value isnt 0
                // Send an extra because UDP packets can be lost
                self.sendCommand(self.moveCommand)
//                self.moveTimer.invalidate()
            }
            // Send 2 because UDP packets can be lost
            self.sendCommand(self.moveCommand)
//        }
    }
    
    func sendCommand(_ command: String) {
        guard let data = command.data(using: .utf8),
            let udpClient = commandClient else {
                print("Error: cannot send command")
                return
        }
        print("Sending Command: \(command)")
        udpClient.sendAndReceive(data)
        
    }
    
    // MARK: - Handle Stream Data
    
    /// Read data from the ongoing STATE stream
    private func handleCommandResponse(message: Data) {
        guard let message = String(data: message, encoding: .utf8), message == "ok" else {
            print("Error with command client response")
            return
        }
        print("Command: ok")
        commandable = true
    }
    /// Read data from the ongoing STATE stream
    private func handleStateStream(data: Data) {
        guard let message = String(data: data, encoding: .utf8) else {
                print("Error with command client response")
                return
        }
        let stateValues = message.split(separator: ";")
        let batteryLevel = stateValues.first(where: { $0.hasPrefix("bat") })
        battery = batteryLevel?.split(separator: ":").last?.description ?? ""
    }
}
