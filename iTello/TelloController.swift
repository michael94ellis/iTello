//
//  TelloController.swift
//  iTello
//
//  Created by Michael Ellis on 12/13/21.
//  Copyright © 2021 Mellis. All rights reserved.
//
//  Tech Specs
//  https://dl-cdn.ryzerobotics.com/downloads/Tello/Tello%20SDK%202.0%20User%20Guide.pdf


import Combine
import Foundation
import SwiftUI

protocol TelloAVDelegate: AnyObject {
    func sendCommand(_ command: String)
}

class TelloController: ObservableObject {
    
    /// Indicates whether or not this TelloController has it's UDP connections setup
    /// If the TelloController is not connected then when the app detects the Tello WiFi connection it will establish the UDP connections
    /// By UDP connection I mean Broadcasters and Receivers, it's not TCP after all
    @Published private(set) public var connected = false
    /// Indicates if the Tello is in its Command mode, where it responds to commands via WiFi/UDP
    @Published private(set) public var commandable = false
    /// Indicates if the Tello is sending Video Stream Data
    @Published private(set) public var streaming = false
    /// Last known battery amount received from tello
    @Published private(set) public var battery = ""
    /// Last known Signal to Noise ratio for WiFi received from tello
    @Published private(set) public var wifi = ""

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
    private var commandClient: UDPClient?
    private var commandClientResponseListener: AnyCancellable?
    private var stateListener: UDPListener?
    private var stateResponseListener: AnyCancellable?
    /// Used for broadcasting movement commands to the drone, uses `commandDelay`
    private var commandBroadcaster: AnyCancellable?
    
    lazy var videoManager: VideoStreamManager = VideoStreamManager()
    
    func beginCommandMode() {
        self.connected = true
        self.commandClient = UDPClient(address: Tello.IPAddress, port: Tello.CommandPort)
        self.commandClientResponseListener = self.commandClient?.$messageReceived.dropFirst().receive(on: DispatchQueue.main).sink(receiveValue: { newMessage in
            self.handleCommandResponse(for: newMessage)
        })
        self.initializeCommandMode()
    }
    
    func exitCommandMode() {
        self.connected = false
        self.commandClient?.cancel()
        self.commandClient = nil
        self.commandClientResponseListener?.cancel()
        self.commandClientResponseListener = nil
    }
    
    /// Repeats a comment until an `ok` is received from the Tello
    private func initializeCommandMode() {
        self.commandBroadcaster = Timer.publish(every: 2, on: .main, in: .default)
            .autoconnect()
            .sink(receiveValue: { _ in
                guard self.commandable,
                      self.streaming else {
                    self.sendCommand(CMD.on)
                    self.sendCommand(CMD.streamOn)
                    return
                }
                self.commandBroadcaster?.cancel()
                // Start listening for state updates
                self.stateListener = UDPListener(on: Tello.StatePort)
                self.stateResponseListener = self.stateListener?.$messageReceived.receive(on: DispatchQueue.main).sink(receiveValue: { newStateData in
                    self.handleStateStream(data: newStateData)
                })
                // Start video stream processing
                self.videoManager.setup()
            })
    }
    
    private func sendCommand(_ command: String) {
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
        self.sendCommand(CMD.takeOff)
    }
    /// Can sometimes be ignored, especially if within first 5 seconds or so of flight time
    func land() {
        self.sendCommand(CMD.land)
    }
    /// EMERGENCY STOP, drone motors will cease immediately, should not always be viasible to user
    func emergencyLand() {
        self.sendCommand(CMD.off)
    }
    /// See the FLIP enum for list of available flip directions
    func flip(_ direction: FLIP) {
        self.sendCommand(direction.commandValue)
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
            print("Commandable Mode Initiated")
            return
        }
        guard self.streaming else {
            self.streaming = true
            print("Video Stream Initiated")
            return
        }
    }
    
    /// Read data from the ongoing STATE stream
    private func handleStateStream(data: Data?) {
        guard let data = data,
              let message = String(data: data, encoding: .utf8) else {
                print("Error with command client response")
                return
        }
        let stateValues = message.split(separator: ";")
        let batteryLevel = stateValues.first(where: { $0.hasPrefix("bat") })
        battery = batteryLevel?.split(separator: ":").last?.description ?? ""
    }
}
