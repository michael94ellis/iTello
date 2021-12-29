//
//  LinearGradient-Extension.swift
//  iTello
//
//  Created by Michael Ellis on 12/6/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

extension LinearGradient {
    init(_ colors: Color...) {
        self.init(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
extension CGPoint {
    internal static func -(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
