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
    
    @ObservedObject var tello: TelloController
    @Binding var displaySettings: Bool
    @State var alertDisplayed: Bool = false
    @StateObject var leftJoystick: JoystickMonitor = JoystickMonitor()
    @StateObject var rightJoystick: JoystickMonitor = JoystickMonitor()
    @State var image: CGImage?
    
    let flips = [FLIP.f, FLIP.l, FLIP.r, FLIP.b]
    let flipImageNames = ["arrow.uturn.forward",
                          "arrow.uturn.up",
                          "arrow.uturn.down",
                          "arrow.uturn.backward"]
    @State var randomFlipImage: String = "arrow.uturn.forward"
    
    @ViewBuilder func flipButton(for flip: FLIP, imageName: String) -> some View {
        Button(action: {
            self.tello.flip(flip)
        }) {
            Image(systemName: imageName).resizable()
                .frame(width: 30, height: 30, alignment: .bottom)
                .foregroundColor(.telloBlue)
        }
        .contentShape(Rectangle())
    }
    
    @ViewBuilder func randomFlipButton() -> some View {
        Button(action: {
            let newIndex = Int.random(in: 0...3)
            self.randomFlipImage = self.flipImageNames[newIndex]
            self.tello.flip(flips[newIndex])
        }) {
            Image(systemName: self.randomFlipImage).resizable()
                .frame(width: 30, height: 30, alignment: .bottom)
                .foregroundColor(.telloBlue)
        }
        .contentShape(Rectangle())
    }
    
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
                    } else if let theurl = theurl {
                        VideoPlayer(player: AVPlayer(url: theurl))
                            .frame(height: 100)
                    }
                }
                .frame(width: parent.size.width * 0.65)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if TelloSettings.showAllFlipButtons {
                            ForEach(0...3, id: \.self) { index in
                                self.flipButton(for: self.flips[index], imageName: self.flipImageNames[index])
                            }
                        } else if TelloSettings.showRandomFlipButton {
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
                        if TelloSettings.showCameraButton {
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
                        if TelloSettings.showRecordVideoButton {
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
                        Button(action: {
                            self.tello.land()
                        }) {
                            Image(systemName: "pause.fill").resizable()
                                .foregroundColor(.telloBlue)
                        }
                        .frame(width: 45, height: 45)
                        .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                        .contentShape(Rectangle())
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
