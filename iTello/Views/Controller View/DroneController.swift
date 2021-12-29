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
    
    @AppStorage("showFlipButtons") public var showFlipButtons: Int = 0
    @AppStorage("showCameraButton") public var showCameraButton: Bool = true
    @AppStorage("showJoysticks") public var showJoysticks: Bool = true
    @AppStorage("showRecordVideoButton") public var showRecordVideoButton: Bool = false
    
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
            }
            .frame(width: 45, height: 45)
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
                if self.showJoysticks {
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
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.clear)
                                .gesture(
                                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                        .onChanged({ value in
                                            var thumbDistance = value.location - value.startLocation
                                            thumbDistance.y = thumbDistance.y * -1
                                            if thumbDistance.x > 100 { thumbDistance.x = 100 }
                                            else if thumbDistance.x < -100 { thumbDistance.x = -100 }
                                            if thumbDistance.y > 100 { thumbDistance.y = 100 }
                                            else if thumbDistance.y < -100 { thumbDistance.y = -100 }
                                            self.leftJoystick.xyPoint = thumbDistance
                                        })
                                        .onEnded({ value in
                                            self.leftJoystick.xyPoint = .zero
                                        })
                                )
                                .onReceive(self.leftJoystick.$xyPoint.receive(on: self.joystickQueue), perform: { leftThumbPoint in
                                    self.tello.yaw = Int(leftThumbPoint.x)
                                    self.tello.upDown = Int(leftThumbPoint.y)
                                    self.tello.beginMovementBroadcast()
                                })
                            Rectangle()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.clear)
                                .gesture(
                                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                        .onChanged({ value in
                                            var thumbDistance = value.location - value.startLocation
                                            thumbDistance.y = thumbDistance.y * -1
                                            if thumbDistance.x > 100 { thumbDistance.x = 100 }
                                            else if thumbDistance.x < -100 { thumbDistance.x = -100 }
                                            if thumbDistance.y > 100 { thumbDistance.y = 100 }
                                            else if thumbDistance.y < -100 { thumbDistance.y = -100 }
                                            self.rightJoystick.xyPoint = thumbDistance
                                        })
                                        .onEnded({ value in
                                            self.rightJoystick.xyPoint = .zero
                                        })
                                )
                                .onReceive(self.rightJoystick.$xyPoint.receive(on: self.joystickQueue), perform: { rightThumbPoint in
                                    self.tello.leftRight = Int(rightThumbPoint.x)
                                    self.tello.forwardBack = Int(rightThumbPoint.y)
                                    self.tello.beginMovementBroadcast()
                                })
                        }
                        .padding(parent.size.width / 20)
                        .edgesIgnoringSafeArea(.all)
                    }
                }
                VStack {
                    if let image = image {
                        Image(decorative: image, scale: 1.0, orientation: .up)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(width: parent.size.width * 0.65)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if self.showFlipButtons == 2 {
                            ForEach(0...3, id: \.self) { index in
                                self.flipButton(for: FLIP.all[index], imageName: self.flipImageNames[index])
                            }
                        } else if self.showFlipButtons == 1 {
                            self.randomFlipButton()
                        }
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
                // Controls
                VStack {
                    HStack {
                        // Take Off Button
                        Button(action: {
                            self.tello.takeOff()
                        }) {
                            Image(systemName: "play.fill").resizable()
                                .foregroundColor(.telloBlue)
                        }
                        .frame(width: 45, height: 45)
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
                                    .foregroundColor(.telloBlue)
                                if self.tello.battery.isEmpty {
                                    Text("Settings")
                                        .foregroundColor(.telloBlue)
                                } else {
                                    Text("Battery: \(self.tello.battery)%")
                                        .font(.body)
                                        .foregroundColor(.telloBlue)
                                }
                            }
                            .padding(.horizontal, 8)
                        })
                            .frame(height: 45)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
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
    
    // MARK: - Flips
    
    private let flipImageNames = ["arrow.uturn.forward",
                                  "arrow.uturn.up",
                                  "arrow.uturn.down",
                                  "arrow.uturn.backward"]
    @State var randomFlipImage: String = "arrow.uturn.forward"
    
    @ViewBuilder func flipButton(for flip: FLIP, imageName: String) -> some View {
        Button(action: {
            self.tello.flip(flip)
        }) {
            Image(systemName: imageName).resizable()
                .frame(width: 40, height: 40, alignment: .bottom)
                .foregroundColor(.telloBlue)
        }
        .contentShape(Rectangle())
    }
    
    @ViewBuilder func randomFlipButton() -> some View {
        Button(action: {
            let newIndex = Int.random(in: 0...3)
            self.randomFlipImage = self.flipImageNames[newIndex]
            self.tello.flip(FLIP.all[newIndex])
        }) {
            Image(systemName: self.randomFlipImage).resizable()
                .frame(width: 40, height: 40, alignment: .bottom)
                .foregroundColor(.telloBlue)
        }
        .contentShape(Rectangle())
    }
}
