//
//  Logger.swift
//  iTello
//
//  Created by Michael Ellis on 12/17/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

//import Foundation
//import Firebase
//
//fileprivate var UserLogs: [String] = []
//fileprivate var firestore = Firestore.firestore()
//
//
//public func print(items: Any..., separator: String = " ", terminator: String = "\n") {
//    let output = items.map { "*\($0)" }.joined(separator: separator)
//    Swift.print(output, terminator: terminator)
//    DispatchQueue.global(qos: .background).async {
//        UserLogs.append(output)
//    }
//}
//
//public func sendLogs() {
//    firestore.collection("UserLogs").addDocument(data: [Date().formatted(): UserLogs]) { err in
//        if let err = err {
//            print("Error sending User Logs: \(err)")
//        } else {
//            print("User Logs Submitted Successfully")
//        }
//    }
//}
