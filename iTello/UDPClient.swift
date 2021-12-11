//
//  UDPClient.swift
//  oTello
//
//  Created by Michael Ellis on 6/1/20.
//  Copyright © 2020 Mellis. All rights reserved.
//

import Network
import Foundation

class UDPClient {
    
    var connection: NWConnection
    var address: NWEndpoint.Host
    var port: NWEndpoint.Port
    var messageReceived: (Data) -> () = { _ in print("Message Receiver not set") }
    var listener: NWListener?
    
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
    }
    
    func setupConnection() {
        connection.stateUpdateHandler = { newState in
            print("Connection \(newState)")
        }
        connection.start(queue: .global())
    }
    
    func setupListener() {
        do {
            listener = try? NWListener(using: .udp, on: port)
            listener?.newConnectionHandler = { incomingUdpConnection in
                print("NWConnection Handler called ")
                incomingUdpConnection.stateUpdateHandler = { udpConnectionState in
                    if udpConnectionState == .ready {
                        print("Listener ready")
                        incomingUdpConnection.receiveMessage(completion: {(data, context, isComplete, error) in
                            guard let data = data, !data.isEmpty else {
                                print("Error no data received")
                                return
                            }
                            self.messageReceived(data)
                        })
                    }
                }
                incomingUdpConnection.start(queue: .global(qos: .userInteractive))
            }
            listener?.start(queue: .global(qos: .userInteractive))
        }
    }
    
    deinit {
        connection.cancel()
        listener?.cancel()
    }
    
    func sendAndReceive(_ data: Data) {
        self.connection.send(content: data, completion: self.resultHandler)
        self.connection.receiveMessage { data, context, isComplete, error in
            guard let data = data else {
                print("Error: Received nil Data")
                return
            }
            self.messageReceived(data)
        }
    }
}

extension UDPClient: Equatable {
    static func == (lhs: UDPClient, rhs: UDPClient) -> Bool {
        lhs.address == rhs.address && lhs.port == rhs.port
    }
}
