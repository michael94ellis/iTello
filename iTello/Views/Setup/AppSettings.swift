//
//  AppSettings.swift
//  iTello
//
//  Created by Michael Ellis on 12/19/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

struct AppSettings: View {
    
    @AppStorage("showRandomFlipButton") public var randomFlipButton: Bool = true
    @AppStorage("showAllFlipButtons") public var allFlipButtons: Bool = false
    @AppStorage("showCameraButton") public var cameraButton: Bool = true
    @AppStorage("showRecordVideoButton") public var recordVideoButton: Bool = false
    
    @Binding var isDisplayed: Bool
    @State var alertDisplayed: Bool = false
    @State var showRecordVideoButton = true
    @State var showRandomFlipButton = true
    @State var showAllFlipButtons = false
    
    @ViewBuilder
    var showRecordingButtonToggle: some View {
        if TelloStoreViewModel.shared.hasPurchasedRecording {
            Toggle("Show Record Button", isOn: self.$recordVideoButton)
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
                .onChange(of: self.showRecordVideoButton, perform: { newValue in
                    self.alertDisplayed = true
                    print("Toggle Unpurchased Record Button")
                })
                .onAppear(perform: {
                    self.showRecordVideoButton = self.showRecordVideoButton
                })
                .alert("Purchase Video Recording?", isPresented: self.$alertDisplayed, actions: {
                    Button(action: {
                        self.alertDisplayed = false
                    }, label: {
                        Text("Maybe Later")
                    })
                    Button(action: {
                        self.alertDisplayed = false
                        print("Purchase Video Recording Begin")
                        TelloStoreViewModel.shared.purchaseVideoRecording()
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
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray))
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
