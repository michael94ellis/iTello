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
import AVKit

struct DroneController: View {
    
    @AppStorage("showCameraButton") public var showCameraButton: Bool = true
    @AppStorage("hideJoysticks") public var hideJoysticks: Bool = false
    @AppStorage("showRecordVideoButton") public var showRecordVideoButton: Bool = false
    @AppStorage("firstTimeNoJoysticks") public var firstTimeNoJoysticks: Bool = true
    
    @ObservedObject var tello: TelloController
    @Binding var displaySettings: Bool
    @State var emergencyLandCounter = 0
    @State var emergencyLandButtonTimer: AnyCancellable?
    @State var alertDisplayed: Bool = false
    @StateObject var leftJoystick: JoystickMonitor = JoystickMonitor()
    @StateObject var rightJoystick: JoystickMonitor = JoystickMonitor()
    @State var image: CGImage?
    
    var joystickQueue: DispatchQueue = DispatchQueue.main
    
    @ViewBuilder var landingButton: some View {
            Button(action: {
                self.tello.land()
                self.emergencyLandCounter += 1
                self.emergencyLandButtonTimer?.cancel()
                self.emergencyLandButtonTimer = Timer.publish(every: 3, on: .main, in: .default).autoconnect().sink(receiveValue: { _ in
                    self.emergencyLandCounter = 0
                    self.emergencyLandButtonTimer?.cancel()
                })
            }) {
                Image(systemName: "pause.fill").resizable()
                    .foregroundColor(.telloBlue)
                    .frame(width: 45, height: 45)
            }
            .frame(width: 70, height: 70)
            .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
            .contentShape(Rectangle())
    }
    @ViewBuilder var emergencyLandButton: some View {
            Button(action: {
                self.tello.land()
                self.emergencyLandCounter += 1
            }) {
                Image(systemName: "hand.raised.slash").resizable()
                    .foregroundColor(.red)
            }
            .frame(width: 45, height: 45)
            .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
            .contentShape(Rectangle())
    }
    
    var body: some View {
        GeometryReader { parent in
            ZStack {
                // Joysticks
                if !self.hideJoysticks {
                    VStack {
                        Spacer()
                        HStack {
                            Joystick(monitor: self.leftJoystick, width: 200)
                                .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                                .onReceive(self.leftJoystick.$xyPoint.receive(on: self.joystickQueue), perform: { leftThumbPoint in
                                    self.tello.yaw = Int(leftThumbPoint.x / 2)
                                    self.tello.upDown = Int(leftThumbPoint.y / 2) * -1
                                    self.tello.beginMovementBroadcast()
                                })
                            Spacer()
                            Joystick(monitor: self.rightJoystick, width: 200)
                                .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                                .onReceive(self.rightJoystick.$xyPoint.receive(on: self.joystickQueue), perform: { rightThumbPoint in
                                    self.tello.leftRight = Int(rightThumbPoint.x / 2)
                                    self.tello.forwardBack = Int(rightThumbPoint.y / 2) * -1
                                    self.tello.beginMovementBroadcast()
                                })
                        }
                        .padding(parent.size.width / 20)
                        .edgesIgnoringSafeArea(.all)
                    }
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
                VStack {
                    if let image = image, !self.hideJoysticks {
                        Image(decorative: image, scale: 1.0, orientation: .up)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: parent.size.width * 0.65, maxHeight: .infinity)
                    } else if let image = image {
                        Image(decorative: image, scale: 1.0, orientation: .up)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Image(systemName: "camera")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                FlipButtons(tello: self.tello)
                // Controls
                VStack {
                    HStack {
                        // Take Off Button
                        Button(action: {
                            self.tello.takeOff()
                        }) {
                            Image(systemName: "play.fill").resizable()
                                .foregroundColor(.telloBlue)
                                .frame(width: 45, height: 45)
                        }
                        .frame(width: 70, height: 70)
                        .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                        .contentShape(Rectangle())
                        Spacer()
                        // Take Photo Button
                        if self.showCameraButton {
                            Button(action: {
                                self.tello.videoManager.takePhoto(cgImage: self.image)
                            }) {
                                Image(systemName: "camera.fill").resizable()
                                    .foregroundColor(.telloBlue)
                            }
                            .frame(width: 40, height: 30)
                            .contentShape(Rectangle())
                            Spacer()
                        }
                        // Settings Button
                        Button(action: {
                            self.displaySettings = true
                        }, label: {
                            HStack {
                                Image(systemName: "gearshape")
                                    .foregroundColor(.white)
                                if self.tello.battery.isEmpty {
                                    Text("Settings")
                                        .foregroundColor(.white)
                                } else {
                                    Text("Battery: \(self.tello.battery)%")
                                        .font(.body)
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 8)
                        })
                            .frame(height: 45)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.5)))
                        Spacer()
                        // Record Video Button
                        if self.showRecordVideoButton {
                            Button(action: {
                                VideoFrameDecoder.shared.videoRecorder.startStop()
                            }) {
                                Image(systemName: VideoFrameDecoder.shared.videoRecorder.isRecording ? "video.slash.fill" : "video.fill").resizable()
                                    .foregroundColor(.telloBlue)
                            }
                            .frame(width: 40, height: 30)
                            .contentShape(Rectangle())
                            Spacer()
                        }
                        // Land Button
                        if self.emergencyLandCounter >= 3 {
                            HStack {
                                self.emergencyLandButton
                                self.landingButton
                            }
                        } else {
                            self.landingButton
                        }
                    }
                    .padding(30)
                    Spacer()
                }
            }
            .onReceive(self.tello.videoManager.$currentFrame.receive(on: DispatchQueue.main), perform: { newImage in
                self.image = newImage
            })
        }
    }
}
