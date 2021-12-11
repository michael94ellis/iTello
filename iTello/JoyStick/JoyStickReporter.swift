//
//  JoyStickReporters.swift
//  oTello
//
//  Created by Michael Ellis on 5/22/20.
//  Copyright © 2020 Mellis. All rights reserved.
//

import Foundation
import CoreGraphics
/**
 JoyStick handle position as X, Y deltas from the base center. Note that here a positive `y` indicates that the
 joystick handle is pushed upwards.
 */
public struct JoyStickXYReporter {
    /// Delta X of handle from base center
    public let x: CGFloat
    /// Delta Y of handle from base center
    public let y: CGFloat

    /**
     Constructor of new XY report
    
     - parameter x: X offset from center of the base
     - parameter y: Y offset from center of the base (positive values towards up/north)
     */
    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
 
    /// Convert this report into polar format
    public var polar: JoyStickPolarReporter {
        return JoyStickPolarReporter(angle: (180.0 - atan2(x, -y) * 180.0 / .pi), displacement: sqrt(x * x + y * y))
    }
}

/**
 JoyStick handle position as angle/displacement values from the base center. Note that `angle` is given in degrees,
 with 0° pointing up (north) and 90° pointing right (east).
 */
public struct JoyStickPolarReporter {
    /// Clockwise angle of the handle with respect to north/up of 0°.
    public let angle: CGFloat
    /// Distance from the center of the base
    public let displacement: CGFloat

    /**
     Constructor of new polar report
    
     - parameter angle: clockwise angle of the handle with respect to north/up of 0°.
     - parameter displacement: distance from the center of the base
     */
    public init(angle: CGFloat, displacement: CGFloat) {
        self.angle = angle
        self.displacement = displacement
    }
    
    /// Convert this report into XY format
    public var rectangular: JoyStickXYReporter {
        let rads = angle * .pi / 180.0
        return JoyStickXYReporter(x: sin(rads) * displacement, y: cos(rads) * displacement)
    }
}
