//
//  iTelloApp.swift
//  iTello
//
//  Created by Michael Ellis on 11/14/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

@main
struct iTelloApp: App {
    
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            GeometryReader { parent in
                VStack {
                    Spacer()
                    HStack {
                        Joystick(width: parent.size.width / 4)
                            .padding(.leading,  parent.size.width / 10)
                        Spacer()
                        Joystick(width: parent.size.width / 4)
                            .padding(.trailing, parent.size.width / 10)
                    }
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

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
                            .foregroundColor(.white)
                        Image(systemName: "arrowtriangle.backward")
                            .offset(x: -arrowOffset, y: 0)
                            .foregroundColor(.white)
                        Image(systemName: "arrowtriangle.up")
                            .offset(x: 0, y: -arrowOffset)
                            .foregroundColor(.white)
                        Image(systemName: "arrowtriangle.down")
                            .offset(x: 0, y: arrowOffset)
                            .foregroundColor(.white)
                        
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
