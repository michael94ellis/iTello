//
//  ControllerJoysticks.swift
//  iTello
//
//  Created by Michael Ellis on 12/30/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI
import SwiftUIJoystick

struct ControllerJoysticks: View {
    
    @AppStorage("hideJoysticks") public var hideJoysticks: Bool = false
    @AppStorage("firstTimeNoJoysticks") public var firstTimeNoJoysticks: Bool = true
    
    @State var alertDisplayed: Bool = false
    
    var parent: GeometryProxy
    @ObservedObject var tello: TelloController
    @ObservedObject var leftJoystick: JoystickMonitor
    @ObservedObject var rightJoystick: JoystickMonitor

    @ViewBuilder var staticJoysticks: some View {
        VStack {
            Spacer()
            HStack {
                Joystick(monitor: self.leftJoystick, width: 200)
                    .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                    .onReceive(self.leftJoystick.$xyPoint.receive(on: RunLoop.main), perform: { leftThumbPoint in
                        self.tello.yaw = Int(leftThumbPoint.x / 2)
                        self.tello.upDown = Int(leftThumbPoint.y / 2) * -1
                        self.tello.beginMovementBroadcast()
                    })
                Spacer()
                Joystick(monitor: self.rightJoystick, width: 200)
                    .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                    .onReceive(self.rightJoystick.$xyPoint.receive(on: RunLoop.main), perform: { rightThumbPoint in
                        self.tello.leftRight = Int(rightThumbPoint.x / 2)
                        self.tello.forwardBack = Int(rightThumbPoint.y / 2) * -1
                        self.tello.beginMovementBroadcast()
                    })
            }
            .padding(parent.size.width / 20)
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    var body: some View {
        if !self.hideJoysticks {
            self.staticJoysticks
        } else {
            VStack {
                HStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onChanged({ value in
                                    var thumbDistance = value.location - value.startLocation
                                    thumbDistance.y = thumbDistance.y * -1
                                    if thumbDistance.x > 100 { thumbDistance.x = 100 }
                                    else if thumbDistance.x < -100 { thumbDistance.x = -100 }
                                    if thumbDistance.y > 100 { thumbDistance.y = 100 }
                                    else if thumbDistance.y < -100 { thumbDistance.y = -100 }
                                    self.tello.yaw = Int(thumbDistance.x)
                                    self.tello.upDown = Int(thumbDistance.y)
                                    self.tello.beginMovementBroadcast()
                                    
                                })
                                .onEnded({ value in
                                    self.tello.yaw = 0
                                    self.tello.upDown = 0
                                    self.tello.beginMovementBroadcast()
                                })
                        )
                    Rectangle()
                        .fill(Color.clear)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onChanged({ value in
                                    var thumbDistance = value.location - value.startLocation
                                    thumbDistance.y = thumbDistance.y * -1
                                    if thumbDistance.x > 100 { thumbDistance.x = 100 }
                                    else if thumbDistance.x < -100 { thumbDistance.x = -100 }
                                    if thumbDistance.y > 100 { thumbDistance.y = 100 }
                                    else if thumbDistance.y < -100 { thumbDistance.y = -100 }
                                    self.tello.leftRight = Int(thumbDistance.x)
                                    self.tello.forwardBack = Int(thumbDistance.y)
                                    self.tello.beginMovementBroadcast()
                                    
                                })
                                .onEnded({ value in
                                    self.tello.leftRight = 0
                                    self.tello.forwardBack = 0
                                    self.tello.beginMovementBroadcast()
                                })
                        )
                }
                .padding(parent.size.width / 20)
                .edgesIgnoringSafeArea(.all)
            }
            .onAppear {
                if self.hideJoysticks && self.firstTimeNoJoysticks {
                    self.alertDisplayed = true
                    self.firstTimeNoJoysticks = false
                }
            }
            .alert("Touch and drag anywhere on either the left or right half of the screen to move the Tello", isPresented: self.$alertDisplayed, actions: {
                Button(action: {
                    self.alertDisplayed = false
                }, label: {
                    Text("OK")
                })
            })
        }
    }
}
