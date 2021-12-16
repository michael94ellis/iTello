//
//  TelloController.swift
//  iTello
//
//  Created by Michael Ellis on 12/13/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import Combine
import Foundation

protocol TelloAVDelegate: AnyObject {
    func sendCommand(_ command: String)
}

class TelloController: ObservableObject {
    
    // TODO: Timer to send a message(CMD.on) after every 4 second the user hasn't sent a command to keep the drone active
    
    @Published private(set) var commandable = false
    @Published private(set) var streaming = false
    /// Last known battery amount received from tello
    @Published var battery = ""
    /// Last known Signal to Noise ratio for WiFi received from tello
    @Published var wifi = ""
    
    /// This var will decrease as the initial command is sent multiple times
    private var commandRepeatMax = 4
    /// Prevents too many movement commands from being issued at once
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
    
    // UDP Connections
    var commandClient: UDPClient?
    var commandClientListener: UDPClient?
    var commandClientResponseHandler: AnyCancellable?
    var stateClient: UDPClient?
    var stateClientListener: UDPClient?
    var stateClientResponseHandler: AnyCancellable?
    /// Used for broadcasting movement commands to the drone, uses `commandDelay`
    var commandBroadcaster: AnyCancellable?
    
    init() {
        self.commandClient = UDPClient(address: Tello.IPAddress, port: Tello.CommandPort)
        self.commandClientListener = UDPClient(address: Tello.IPAddress, port: Tello.CommandPort, isListener: true)
        self.commandClientResponseHandler = self.commandClientListener?.$messageReceived.sink(receiveValue: { newMessage in
            self.handleCommandResponse(for: newMessage)
        })
        self.repeatCommandForResponse()
    }
    
    /// Repeats a comment until an `ok` is received from the Tello
    private func repeatCommandForResponse() {
        self.commandBroadcaster = Timer.publish(every: 2, on: .main, in: .default)
            .autoconnect()
            .sink(receiveValue: { _ in
                guard self.commandable else {
                    self.sendCommand(CMD.on)
                    return
                }
                self.commandBroadcaster?.cancel()
            })
    }
    
    func sendCommand(_ command: String) {
        guard let data = command.data(using: .utf8),
            let udpClient = commandClient else {
                print("Error: cannot send command")
                return
        }
        print("Sending Command: \(command)")
        udpClient.sendData(data)
    }
    
    // MARK: - Tello Command Methods
    
    
    /// Handles continuous movement events from the Joysticks, limiting output commands to once per `commandDelay`
    func joystickMovementHandler() {
        self.commandBroadcaster = Timer.publish(every: self.commandDelay, on: .main, in: .default)
            .autoconnect()
            .sink(receiveValue: { timer in
                // Concatenate the 4 int values and compare to 0 using bitwise operator AND(&)
                if self.leftRight & self.forwardBack & self.upDown & self.yaw == 0 {
                    // The joysticks go back to 0 when the user lets go, therefore if the value isnt 0
                    // Send an extra because UDP packets can be lost
                    self.sendCommand(self.moveCommand)
                    self.engageIdleState()
                }
                // Send 2 because UDP packets can be lost
                self.sendCommand(self.moveCommand)
            })
    }
    
    /// Prevents controller from losing control of the tello device
    func engageIdleState() {
        self.commandBroadcaster = Timer.publish(every: 4, on: .main, in: .default)
            .autoconnect()
            .sink(receiveValue: { timer in
                self.sendCommand(self.moveCommand)
            })
    }
    
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
    
    /// Read data from the drone's response to a given command
    private func handleCommandResponse(for messageData: Data?) {
        guard let messageData = messageData,
              let message = String(data: messageData, encoding: .utf8), message == "ok" else {
                  print("Error with command client response - \(String(describing: messageData))")
            return
        }
        print("Command Response: \(message)")
        guard self.commandable else {
            self.commandable = true
            print("Commandable Mode Engage")
            return
        }
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
