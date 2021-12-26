//
//  Logger.swift
//  iTello
//
//  Created by Michael Ellis on 12/26/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import Foundation
import FirebaseCrashlytics

public func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let output = items.map { "\($0)" }.joined(separator: separator)
    Swift.print(output, terminator: terminator)
    DispatchQueue.global(qos: .background).async {
        Crashlytics.crashlytics().log(output)
    }
}

public func logError(_ error: Error) {
    Crashlytics.crashlytics().record(error: error)
}
