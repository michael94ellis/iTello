//
//  Logger.swift
//  iTello
//
//  Created by Michael Ellis on 12/17/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import Foundation
import FirebaseFirestore
import Firebase
import SwiftUI

// No one likes globals but this is a hobby project so logging isn't a strong requirement
fileprivate var UserLogs: [String] = []
fileprivate var firestore = Firestore.firestore()

public func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let output = items.map { "\($0)" }.joined(separator: separator)
    Swift.print(output, terminator: terminator)
    DispatchQueue.global(qos: .background).async {
        UserLogs.append(output)
    }
}

public func sendLogs() {
    print(UserLogs)
    firestore.collection("UserLogs").addDocument(data: [Date().formatted(): UserLogs]) { err in
        if let err = err {
            print("Error sending User Logs: \(err)")
        } else {
            print("User Logs Submitted Successfully")
        }
    }
}

struct SendLogsButton: View {
    var body: some View {
        Button(action: {
            sendLogs()
        }) {
            Text("Problems? Tap To Send Logs")
                .fontWeight(.semibold)
                .foregroundColor(Color.white)
                .frame(width: 200, height: 60)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray))
        }
        .contentShape(Rectangle())
    }
}
