//
//  UDPClient.swift
//  oTello
//
//  Created by Michael Ellis on 6/1/20.
//  Copyright © 2020 Mellis. All rights reserved.
//

import Network
import Foundation

protocol UDPListener {
    func handleResponse(_ client: UDPClient, data: Data)
}

class UDPClient {
    
    var connection: NWConnection
    var address: NWEndpoint.Host
    var port: NWEndpoint.Port
    var delegate: UDPListener?
    
    var resultHandler = NWConnection.SendCompletion.contentProcessed { NWError in
        guard NWError == nil else {
            print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
            return
        }
    }

    init?(address newAddress: String, port newPort: Int32) {
        guard let codedAddress = IPv4Address(newAddress),
            let codedPort = NWEndpoint.Port(rawValue: NWEndpoint.Port.RawValue(newPort)) else {
                print("Failed to create connection address")
                return nil
        }
        address = .ipv4(codedAddress)
        port = codedPort
        
        connection = NWConnection(host: address, port: port, using: .udp)
        connection.stateUpdateHandler = { newState in
            print("Connection \(newState)")
        }
        connection.start(queue: .global())
    }
    
    deinit {
        connection.cancel()
    }
    
    func sendAndReceive(_ data: Data) {
        self.connection.send(content: data, completion: self.resultHandler)
        self.connection.receiveMessage { data, context, isComplete, error in
            guard let data = data else {
                print("Error: Received nil Data")
                return
            }
            guard self.delegate != nil else {
                print("Error: UDPClient response handler is nil")
                return
            }
            self.delegate?.handleResponse(self, data: data)
        }
    }
}

extension UDPClient: Equatable {
    static func == (lhs: UDPClient, rhs: UDPClient) -> Bool {
        lhs.address == rhs.address && lhs.port == rhs.port
    }
}
