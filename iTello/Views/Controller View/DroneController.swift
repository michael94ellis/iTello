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
                .frame(width: 45, height: 45)
        }
        .frame(width: 70, height: 70)
        .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder var takeOffButton: some View {
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
    }
    
    @ViewBuilder var takePhotoButton: some View {
        Button(action: {
            self.tello.videoManager.takePhoto(cgImage: self.image)
        }) {
            Image(systemName: "camera.fill").resizable()
                .foregroundColor(.telloBlue)
        }
        .frame(width: 40, height: 30)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder var settingsButton: some View {
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
    }
    
    @ViewBuilder var recordVideoButton: some View {
        Button(action: {
            VideoFrameDecoder.shared.videoRecorder.startStop()
        }) {
            Image(systemName: VideoFrameDecoder.shared.videoRecorder.isRecording ? "video.slash.fill" : "video.fill").resizable()
                .foregroundColor(.telloBlue)
        }
        .frame(width: 40, height: 30)
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
                VStack {
                    if let image = image {
                        Image(decorative: image, scale: 1.0, orientation: .up)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: parent.size.width, maxHeight: parent.size.height)
                    }
                }
                // Joysticks
                ControllerJoysticks(parent: parent, tello: self.tello, leftJoystick: self.leftJoystick, rightJoystick:  self.rightJoystick)
                FlipButtons(tello: self.tello)
                // Controls
                VStack {
                    HStack {
                        // Take Off Button
                        self.takeOffButton
                        Spacer()
                        // Take Photo Button
                        if self.showCameraButton {
                            self.takePhotoButton
                            Spacer()
                        }
                        // Settings Button
                        self.settingsButton
                        Spacer()
                        // Record Video Button
                        if self.showRecordVideoButton {
                            self.recordVideoButton
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
