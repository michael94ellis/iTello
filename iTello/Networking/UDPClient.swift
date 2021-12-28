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
    
    var resultHandler = NWConnection.SendCompletion.contentProcessed { NWError in
        guard NWError == nil else {
            print("ERROR! Error sending data. NWError: \n \(NWError!)")
            return
        }
    }
    
    init?(address newAddress: String, port newPort: NWEndpoint.Port) {
        guard let codedAddress = IPv4Address(newAddress) else {
            print("Failed to create connection address")
            return nil
        }
        address = .ipv4(codedAddress)
        port = newPort
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
            }
        }
        connection.viabilityUpdateHandler = { [self] isViable in
            print("Connection \(port) Viability - \(isViable)")
        }
        connection.start(queue: .global())
    }
    
    func cancel() {
        self.isReady = false
        self.connection.cancel()
    }
    
    deinit {
        self.cancel()
    }
    
    func sendData(_ data: Data) {
        self.connection.send(content: data, completion: self.resultHandler)
        self.receive()
    }
    
    func receive() {
        self.connection.receiveMessage { data, context, isComplete, error in
            print("Receive completed: " + isComplete.description)
            guard let data = data else {
                print("Error: Received nil Data")
                return
            }
            print(String(data: data, encoding: .utf8) ?? "Error: Cannot parse response")
            self.messageReceived = data
            self.receive()
        }
    }
}

