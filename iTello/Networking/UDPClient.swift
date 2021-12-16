//
//  UDPClient.swift
//  iTello
//
//  Created by Michael Ellis on 6/1/20.
//  Copyright © 2020 Mellis. All rights reserved.
//

import Network
import Foundation
import Combine

class UDPClient: ObservableObject {
    
    var connection: NWConnection
    var address: NWEndpoint.Host
    var port: NWEndpoint.Port
    @Published private(set) public var messageReceived: Data?
    @Published private(set) public var isReady: Bool = false
    @Published var isListening: Bool
    
    var resultHandler = NWConnection.SendCompletion.contentProcessed { NWError in
        guard NWError == nil else {
            print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
            return
        }
        print("Data sent")
    }
    
    init?(address newAddress: String, port newPort: Int32, isListener: Bool = false) {
        self.isListening = isListener
        guard let codedAddress = IPv4Address(newAddress),
              let codedPort = NWEndpoint.Port(rawValue: NWEndpoint.Port.RawValue(newPort)) else {
                  print("Failed to create connection address")
                  return nil
              }
        address = .ipv4(codedAddress)
        port = codedPort
        let localEndpoint = NWEndpoint.hostPort(host: address, port: port)
        let parameters = NWParameters.udp
        parameters.allowLocalEndpointReuse = true
        parameters.allowFastOpen = true
        parameters.prohibitedInterfaceTypes = [.cellular]
        connection = NWConnection(to: localEndpoint, using: parameters)
        connection.stateUpdateHandler = { newState in
            print("Connection \(newState)")
            if newState == .ready {
                self.isReady = true
                if isListener {
                    self.receive()
                }
            }
        }
        connection.viabilityUpdateHandler = { [self] isViable in
            print("Connection \(port) Viability - \(isViable)")
        }
        connection.start(queue: .global())
    }
    
    func cancel() {
        self.isListening = false
        self.connection.cancel()
    }
    
    deinit {
        connection.cancel()
    }
    
    func sendData(_ data: Data) {
        self.connection.send(content: data, completion: self.resultHandler)
        self.receive()
    }
    
    func receive() {
        self.connection.receiveMessage { data, context, isComplete, error in
            print("Receive isComplete: " + isComplete.description)
            guard let data = data else {
                print("Error: Received nil Data")
                return
            }
            print(String(data: data, encoding: .utf8) ?? "Sent Data")
            self.messageReceived = data
            if self.isListening {
                self.receive()
            }
        }
    }
}

