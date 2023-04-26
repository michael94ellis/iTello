//
//  AppSettings.swift
//  iTello
//
//  Created by Michael Ellis on 12/19/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

struct AppSettings: View {
    
    // Paid Feature
    @AppStorage("showRecordVideoButton") public var showRecordVideoButton: Bool = false
    @AppStorage("hideJoysticks") public var hideJoysticks: Bool = true
    
    // Free Features
    @ObservedObject var tello: TelloController
    @Binding var isDisplayed: Bool
    @Binding var mediaGalleryDisplayed: Bool
    @State var alertDisplayed: Bool = false
    @AppStorage("showCameraButton") public var cameraButton: Bool = true
    @AppStorage("showFlipButtons") public var showFlipButtons: Int = 0
    @State private var selectedFlip = 0
    @State private var showHideJoystickWarning = false

    @ViewBuilder
    var showRecordingButtonToggle: some View {
        Toggle("Show Record Button", isOn: self.$showRecordVideoButton)
            .frame(height: 30)
            .foregroundColor(.white)
            .padding(.horizontal)
            .onChange(of: self.showRecordVideoButton, perform: { newValue in
                self.showRecordVideoButton = newValue
            })
            .onAppear(perform: {
                self.showRecordVideoButton = self.showRecordVideoButton
            })
    }
    
    @ViewBuilder
    var showJoysticksToggle: some View {
        Toggle("Hide Joysticks", isOn: self.$hideJoysticks)
            .frame(height: 30)
            .foregroundColor(.white)
            .padding(.horizontal)
            .onChange(of: self.hideJoysticks, perform: { newValue in
                if newValue {
                    self.showHideJoystickWarning = true
                } else {
                    self.hideJoysticks = false
                }
            })
            .onAppear(perform: {
                self.hideJoysticks = self.hideJoysticks
            })
            .alert("Warning",
                   isPresented: $showHideJoystickWarning,
                   actions: {
                Button("OK", action: { self.hideJoysticks = true })
                Button("Cancel", action: {
                    self.hideJoysticks = false
                    self.showHideJoystickWarning = false
                })
            }, message: { Text("Joysticks will become hidden! The left and right sides of the screen become invisible joysticks.") })
    }
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                MediaGalleryButton(displayMediaGallery: self.$mediaGalleryDisplayed)
                SetupWiFiButton(displayPopover: self.$isDisplayed)
                    .frame(width: 300)
                    .onReceive(self.tello.$commandable.dropFirst().receive(on: DispatchQueue.main), perform: { [self] commandable in
                        // Listen for successful command mode initialization and then remove the setup popover
                        self.isDisplayed = !commandable
                    })
            }
            .frame(width: 600, height: 125)
            HStack {
                VStack {
                    Spacer()
                    Toggle("Show Camera Button", isOn: self.$cameraButton)
                        .frame(height: 30)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .onChange(of: self.cameraButton, perform: { newValue in
                            self.cameraButton = newValue
                        })
                        .onAppear(perform: {
                            self.cameraButton = self.cameraButton
                        })
                    Spacer()
                    self.showRecordingButtonToggle
                    Spacer()
                    self.showJoysticksToggle
                    Divider()
                        .padding(.horizontal)
                    Text("Show Flip Button(s)")
                    Picker("Flip Button(s)", selection: self.$selectedFlip) {
                        Text("None").tag(0)
                        Text("Random").tag(1)
                        Text("All").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 8)
                    .onChange(of: self.selectedFlip, perform: { selectedFlipValue in
                        self.showFlipButtons = selectedFlipValue
                    })
                    .onAppear {
                        self.selectedFlip = self.showFlipButtons
                    }
                    Spacer()
                }
                .foregroundColor(.white)
                .frame(width: 300, height: 200)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.telloBlue))
                VStack {
                    SetupInstructions()
                    Button(action: {
                        self.isDisplayed = false
                    }) {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundColor(Color.white)
                            .frame(width: 300)
                            .frame(maxHeight: .infinity)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray))
                    }
                    .contentShape(Rectangle())
                }
                .frame(width: 300, height: 200)
            }
            Spacer()
        }
    }
}
