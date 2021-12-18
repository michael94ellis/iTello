//
//  DroneController.swift
//  iTello
//
//  Created by Michael Ellis on 12/7/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI
import SwiftUIJoystick
import Combine

struct DroneController: View {
    
    @ObservedObject var tello: TelloController
    @Binding var displaySettings: Bool
    @StateObject var leftJoystick: JoystickMonitor = JoystickMonitor(width: 100)
    @StateObject var rightJoystick: JoystickMonitor = JoystickMonitor(width: 100)
    @State var image: CGImage?
    
    var body: some View {
        GeometryReader { parent in
            ZStack {
                VStack {
                    HStack {
                        Button(action: {
                            self.tello.takeOff()
                        }) {
                            Image(systemName: "play.fill").resizable()
                        }
                        .frame(width: parent.size.width / 15, height: parent.size.width / 15)
                        .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                        .contentShape(Rectangle())
                        .padding(.leading,  parent.size.width / 20)
                        Spacer(minLength: parent.size.width / 6)
                        Button(action: {
                            self.displaySettings.toggle()
                        }, label: {
                            Image(systemName: "gearshape")
                            Text("Battery: \(self.tello.battery)%")
                                .font(.body)
                        })
                            .frame(height: parent.size.height / 20)
                        Spacer(minLength: parent.size.width / 6)
                        Button(action: {
                            self.tello.land()
                        }) {
                            Image(systemName: "pause.fill").resizable()
                        }
                        .frame(width: parent.size.width / 15, height: parent.size.width / 15)
                        .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                        .contentShape(Rectangle())
                        .padding(.trailing, parent.size.width / 20)
                    }
                    .padding(.top, 30)
                    Spacer()
                    HStack {
                        Joystick(monitor: self.leftJoystick, width: parent.size.width / 4)
                            .padding(.leading, parent.size.width / 10)
                            .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                            .onReceive(self.leftJoystick.$xyPoint, perform: { leftThumbPoint in
                                self.tello.upDown = Int(leftThumbPoint.x) - Int(parent.size.width) / 2
                                self.tello.yaw = Int(leftThumbPoint.y) - Int(parent.size.width) / 2
                            })
                        Spacer()
                        Joystick(monitor: self.rightJoystick, width: parent.size.width / 4)
                            .padding(.trailing, parent.size.width / 10)
                            .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                            .onReceive(self.rightJoystick.$xyPoint, perform: { rightThumbPoint in
                                self.tello.leftRight = Int(rightThumbPoint.x) - Int(parent.size.width) / 2
                                self.tello.forwardBack = Int(rightThumbPoint.y) - Int(parent.size.width) / 2
                            })
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                VStack {
                    if let image = image {
                        Image(decorative: image, scale: 1.0, orientation: .up)
                            .frame(width: 300, height: 200)
                            .border(Color.red)
                    } else {
                        Image(systemName: "plus")
                            .frame(width: 300, height: 200)
                    }
                }
                .border(Color.red)
            }
            .onReceive(self.tello.videoManager.$currentFrame.receive(on: DispatchQueue.main), perform: { newImage in
                self.image = newImage
            })
        }
    }
}
