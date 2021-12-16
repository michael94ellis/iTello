//
//  Joystick.swift
//  iTello
//
//  Created by Michael Ellis on 12/6/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI
import Combine
import SwiftUIJoystick

struct Joystick: View {
    
    var tello: TelloController?
    @State private var joystickMonitor: JoystickMonitor
    private var joyStickListener: AnyCancellable?
    private let dragDiameter: CGFloat
    private let radius: Int
    private let arrowOffset: CGFloat
    
    init(tello: TelloController?, width: CGFloat, isLeft: Bool) {
        self.tello = tello
        self.dragDiameter = width
        self.radius = Int(width) / 2
        self.arrowOffset = (width / 2) - (width / 10)
        self.joystickMonitor = JoystickMonitor(diameter: width)
        if isLeft {
            self.joyStickListener = self.joystickMonitor.$xyPoint.sink(receiveValue: { leftThumbPoint in
                self.tello?.yaw = Int(leftThumbPoint.x) - radius
                self.tello?.upDown = Int(leftThumbPoint.y) - radius
            })
        } else {
            self.joyStickListener = self.joystickMonitor.$xyPoint.sink(receiveValue: { rightThumbPoint in
                self.tello?.leftRight = Int(rightThumbPoint.x) - radius
                self.tello?.forwardBack = Int(rightThumbPoint.y) - radius
            })
        }
    }
    
    var body: some View {
        HStack{
            JoystickBuilder(
                monitor: joystickMonitor,
                width: dragDiameter,
                shape: .circle,
                background: {
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [.darkStart, .darkEnd], center: .center, startRadius: 1, endRadius: 115))
                            .overlay(Circle().stroke(Color.black)
                                        .shadow(color: Color.white, radius: 5))
                        Image(systemName: "arrowtriangle.forward")
                            .offset(x: arrowOffset, y: 0)
                            .foregroundColor(.gray)
                        Image(systemName: "arrowtriangle.backward")
                            .offset(x: -arrowOffset, y: 0)
                            .foregroundColor(.gray)
                        Image(systemName: "arrowtriangle.up")
                            .offset(x: 0, y: -arrowOffset)
                            .foregroundColor(.gray)
                        Image(systemName: "arrowtriangle.down")
                            .offset(x: 0, y: arrowOffset)
                            .foregroundColor(.gray)
                        
                    }
                },
                foreground: {
                    Circle()
                        .fill(RadialGradient(colors: [.white, .gray], center: .center, startRadius: 1, endRadius: 30))
                        .overlay(
                            Circle()
                                .stroke(Color.gray, lineWidth: 4)
                                .blur(radius: 4)
                                .offset(x: 2, y: 2)
                                .mask(Circle().fill(LinearGradient(Color.black, Color.clear)))
                                .shadow(color: Color.white, radius: 5)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 8)
                                .blur(radius: 4)
                                .offset(x: -2, y: -2)
                                .mask(Circle().fill(LinearGradient(Color.clear, Color.black)))
                                .shadow(color: Color.white, radius: 5)
                                .blur(radius: 1)
                        )
                },
                locksInPlace: false)
        }
    }
}
