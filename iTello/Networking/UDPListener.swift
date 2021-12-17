//
//  UDPListener.swift
//  iTello
//
//  Created by Michael Ellis on 12/16/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import Foundation
import Network
import Combine

class UDPListener: ObservableObject {
    
    var listener: NWListener?
    var connection: NWConnection?
    var queue  = DispatchQueue.global(qos: .userInitiated)
    @Published private(set) public var messageReceived: Data?
    @Published private(set) public var isReady: Bool = false
    
    init(on port: NWEndpoint.Port) {
        let params = NWParameters.udp
        self.listener = try? NWListener(using: params, on: port)
        self.listener?.stateUpdateHandler = { update in
            switch update {
            case .ready:
                self.isReady = true
                print("Listener connected to port \(port)")
            case .failed, .cancelled:
                self.isReady = false
                print("Listener disconnected from port \(port)")
            default:
                print("Listener connecting to port \(port)...")
            }
        }
        self.listener?.newConnectionHandler = { connection in
            print("Listener receiving new message")
            self.createConnection(connection: connection)
            self.listener?.cancel()
        }
        self.listener?.start(queue: self.queue)
    }
    
    func createConnection(connection: NWConnection) {
        self.connection = connection
        self.connection?.stateUpdateHandler = { (newState) in
            switch (newState) {
            case .ready:
                print("Listener ready to receive message - \(connection)")
                self.receive()
            case .cancelled, .failed:
                print("Listener failed to receive message - \(connection)")
            default:
                print("Listener waiting to receive message - \(connection)")
            }
        }
        self.connection?.start(queue: .global())
    }
    
    func receive() {
        self.connection?.receiveMessage { data, context, isComplete, error in
            print("Message Received: " + isComplete.description)
            if let unwrappedError = error {
                print("Error: NWError received in \(#function) - \(unwrappedError)")
                return
            }
            guard isComplete, let data = data else {
                print("Error: Received nil Data with context - \(String(describing: context))")
                return
            }
            print(String(data: data, encoding: .utf8) ?? "Sent Data")
            self.messageReceived = data
        }
    }
    
    func endConnection() {
        self.connection?.cancel()
    }
}
