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
    
    // Free Features
    @ObservedObject var tello: TelloController
    @Binding var isDisplayed: Bool
    @State var alertDisplayed: Bool = false
    @AppStorage("showCameraButton") public var cameraButton: Bool = true
    @AppStorage("showRandomFlipButton") public var showRandomFlipButton: Bool = true
    @AppStorage("showAllFlipButtons") public var showAllFlipButtons: Bool = false
    
    @ViewBuilder
    var showRecordingButtonToggle: some View {
        if self.telloStore.hasPurchasedRecording {
            Toggle("Show Record Button", isOn: self.$showRecordVideoButton)
                .frame(height: 30)
                .foregroundColor(.white)
                .padding(.horizontal)
                .onChange(of: self.showRecordVideoButton, perform: { newValue in
                    self.showRecordVideoButton = newValue
                    print("Toggle Purchased Record Button - \(newValue)")
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
                    }, label: {
                        Text("Maybe Later")
                    })
                    Button(action: {
                        self.alertDisplayed = false
                        print("Purchase Video Recording Begin")
                        self.telloStore.purchaseVideoRecording()
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
                MediaGalleryButton()
                SetupWiFiButton(displayPopover: self.$isDisplayed)
                    .frame(width: 300)
                    .onReceive(self.tello.$commandable.receive(on: DispatchQueue.main), perform: { [self] commandable in
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
                    Divider()
                        .padding(.horizontal)
                    Toggle("Show Random Flips Button", isOn: self.$showRandomFlipButton)
                        .frame(height: 30)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .onChange(of: self.showRandomFlipButton, perform: { displayRandomFlipsButton in
                            self.showRandomFlipButton = displayRandomFlipsButton
                            if self.showAllFlipButtons && displayRandomFlipsButton {
                                self.showAllFlipButtons = false
                            }
                        })
                        .onAppear(perform: {
                            self.showRandomFlipButton = self.showRandomFlipButton
                        })
                    Spacer()
                    Toggle("Show All Flip Buttons", isOn: self.$showAllFlipButtons)
                        .frame(height: 30)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .onChange(of: self.showAllFlipButtons, perform: { displayAllFlipButtons in
                            self.showAllFlipButtons = displayAllFlipButtons
                            if self.showRandomFlipButton && displayAllFlipButtons {
                                self.showRandomFlipButton = false
                            }
                        })
                        .onAppear(perform: {
                            self.showAllFlipButtons = self.showAllFlipButtons
                        })
                    Spacer()
                }
                .foregroundColor(.white)
                .frame(width: 300, height: 178)
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
                .frame(width: 300, height: 178)
            }
            Spacer()
        }
    }
}
