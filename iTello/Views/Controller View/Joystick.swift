//
//  Joystick.swift
//  iTello
//
//  Created by Michael Ellis on 12/6/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI
import SwiftUIJoystick

struct Joystick: View {
    
    @State private var joystickMonitor: JoystickMonitor
    private var dragDiameter: CGFloat
    private let arrowOffset: CGFloat
    
    init(width: CGFloat) {
        self.dragDiameter = width
        self.arrowOffset = (width / 2) - (width / 10)
        self.joystickMonitor = JoystickMonitor(diameter: width)
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
