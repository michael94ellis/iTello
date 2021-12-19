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
    @StateObject var leftJoystick: JoystickMonitor = JoystickMonitor()
    @StateObject var rightJoystick: JoystickMonitor = JoystickMonitor()
    @State var image: CGImage?
    
    var body: some View {
        GeometryReader { parent in
            ZStack {
                // Joysticks
                VStack {
                    Spacer()
                    HStack {
                        Joystick(monitor: self.leftJoystick, width: 200)
                            .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                            .onReceive(self.leftJoystick.$xyPoint, perform: { leftThumbPoint in
                                self.tello.yaw = Int(leftThumbPoint.x)
                                self.tello.upDown = Int(leftThumbPoint.y)
                            })
                        Spacer()
                        Joystick(monitor: self.rightJoystick, width: 200)
                            .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                            .onReceive(self.rightJoystick.$xyPoint, perform: { rightThumbPoint in
                                self.tello.leftRight = Int(rightThumbPoint.x)
                                self.tello.forwardBack = Int(rightThumbPoint.y)
                            })
                    }
                    .padding(parent.size.width / 20)
                    .edgesIgnoringSafeArea(.all)
                }
                VStack {
                    if let image = image {
                        Image(decorative: image, scale: 1.0, orientation: .up)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(width: parent.size.width * 0.65)
                // Controls
                VStack {
                    HStack {
                        Button(action: {
                            self.tello.takeOff()
                        }) {
                            Image(systemName: "play.fill").resizable()
                        }
                        .frame(width: 55, height: 55)
                        .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                        .contentShape(Rectangle())
                        Spacer()
                        Button(action: {
                            self.tello.videoManager.takePhoto(cgImage: self.image)
                        }) {
                            Image(systemName: "camera.fill").resizable()
                        }
                        .frame(width: 30, height: 25)
                        .contentShape(Rectangle())
                        Spacer()
                        Button(action: {
                            self.displaySettings.toggle()
                        }, label: {
                            HStack {
                                Image(systemName: "gearshape")
                                if self.tello.battery.isEmpty {
                                    Text("Settings")
                                } else {
                                    Text("Battery: \(self.tello.battery)%")
                                        .font(.body)
                                }
                            }
                            .padding(.horizontal, 8)
                        })
                            .frame(height: 35)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.1)))
                        Spacer()
                        Button(action: {
                            VideoFrameDecoder.shared.isRecording.toggle()
                        }) {
                            Image(systemName: VideoFrameDecoder.shared.isRecording ? "video.slash.fill" : "video.fill").resizable()
                        }
                        .frame(width: 30, height: 25)
                        .contentShape(Rectangle())
                        Spacer()
                        Button(action: {
                            self.tello.land()
                        }) {
                            Image(systemName: "pause.fill").resizable()
                        }
                        .frame(width: 55, height: 55)
                        .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                        .contentShape(Rectangle())
                    }
                    .padding(30)
                    HStack {
                        
                        Spacer()
                    }
                    Spacer()
                }
            }
            .onReceive(self.tello.videoManager.$currentFrame.receive(on: DispatchQueue.main), perform: { newImage in
                self.image = newImage
            })
        }
    }
}
