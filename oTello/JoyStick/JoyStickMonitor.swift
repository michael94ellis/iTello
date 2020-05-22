//
//  JoyStickMonitor.swift
//  oTello
//
//  Created by Michael Ellis on 5/22/20.
//  Copyright © 2020 Mellis. All rights reserved.
//

import CoreGraphics

/// Prototype of a monitor function that accepts a JoyStickXYReport.
public typealias JoyStickXYMonitor = (_ value: JoyStickXYReporter) -> Void

/// Prototype of a monitor function that accepts a JoyStickXYReport.
public typealias JoyStickPolarMonitor = (_ value: JoyStickPolarReporter) -> Void

/// Monitor kind. Determines the type of reporting that will be emitted from a JoyStick instance.
public enum JoyStickMonitor {
    /**
     Install monitor that accepts polar position change reports
     
     - parameter monitor: function that accepts a JoyStickPolarReport
     */
    case polar(monitor: JoyStickPolarMonitor)

    /**
     Install monitor that accepts cartesian (XY) position change reports
     
     - parameter monitor: function that accepts a JoyStickXYReport
     */
    case xy(monitor: JoyStickXYMonitor)
    
    /**
     No monitoring for a JoyStick instance.
     */
    case none
}
