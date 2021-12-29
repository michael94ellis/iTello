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
    @ObservedObject var telloStore: TelloStoreViewModel
    @AppStorage("showRecordVideoButton") public var showRecordVideoButton: Bool = false
    @AppStorage("hideJoysticks") public var hideJoysticks: Bool = true
    
    // Free Features
    @ObservedObject var tello: TelloController
    @Binding var isDisplayed: Bool
    @Binding var mediaGalleryDisplayed: Bool
    @State var alertDisplayed: Bool = false
    @State var alertDisplayed2: Bool = false
    @AppStorage("showCameraButton") public var cameraButton: Bool = true
    @AppStorage("showFlipButtons") public var showFlipButtons: Int = 0
    @State private var selectedFlip = 0

    @ViewBuilder
    var showRecordingButtonToggle: some View {
        if self.telloStore.hasPurchasedPro {
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
        } else {
            Toggle("Show Record Button", isOn: self.$alertDisplayed)
                .frame(height: 30)
                .foregroundColor(.white)
                .padding(.horizontal)
                .alert("Purchase Video Recording?", isPresented: self.$alertDisplayed, actions: {
                    Button(action: {
                        self.alertDisplayed = false
                        self.hideJoysticks = false
                        self.showRecordVideoButton = false
                    }, label: {
                        Text("Maybe Later")
                    })
                    Button(action: {
                        self.alertDisplayed = false
                        self.telloStore.purchasePro()
                    }, label: {
                        Text("OK")
                    })
                })
                .onAppear(perform: {
                    self.hideJoysticks = false
                    self.showRecordVideoButton = false
                })
        }
    }
    
    @ViewBuilder
    var showJoysticksToggle: some View {
        if self.telloStore.hasPurchasedPro {
            Toggle("Hide Joysticks", isOn: self.$hideJoysticks)
                .frame(height: 30)
                .foregroundColor(.white)
                .padding(.horizontal)
                .onChange(of: self.hideJoysticks, perform: { newValue in
                    self.hideJoysticks = newValue
                })
                .onAppear(perform: {
                    self.hideJoysticks = self.hideJoysticks
                })
        } else {
            Toggle("Hide Joysticks", isOn: self.$alertDisplayed2)
                .frame(height: 30)
                .foregroundColor(.white)
                .padding(.horizontal)
                .alert("Purchase iTello Pro?", isPresented: self.$alertDisplayed2, actions: {
                    Button(action: {
                        self.alertDisplayed2 = false
                        self.hideJoysticks = false
                        self.showRecordVideoButton = false
                    }, label: {
                        Text("Maybe Later")
                    })
                    Button(action: {
                        self.alertDisplayed2 = false
                        self.telloStore.purchasePro()
                    }, label: {
                        Text("OK")
                    })
                })
        }
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
