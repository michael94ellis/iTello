//
//  AppSettings.swift
//  iTello
//
//  Created by Michael Ellis on 12/19/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

class TelloSettings: ObservableObject {
    @AppStorage("showCameraButton") public static var showCameraButton: Bool = true
    @AppStorage("showRecordVideoButton") public static var showRecordVideoButton: Bool = false
    @AppStorage("showRandomFlipButton") public static var showRandomFlipButton: Bool = true
    @AppStorage("showAllFlipButtons") public static var showAllFlipButtons: Bool = false
}

struct AppSettings: View {
    
    @Binding var isDisplayed: Bool
    @State var alertDisplayed: Bool = false
    @State var showCameraButton = true
    @State var showRecordVideoButton = false
    @State var showVideoStream = true
    @State var showRandomFlipButton = true
    @State var showAllFlipButtons = false
    
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
                    Toggle("Show Camera Button", isOn: self.$showCameraButton)
                        .frame(height: 30)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .onChange(of: self.showCameraButton, perform: { newValue in
                            TelloSettings.showCameraButton = newValue
                        })
                        .onAppear(perform: {
                            self.showCameraButton = TelloSettings.showCameraButton
                        })
                    Spacer()
                    Toggle("Show Record Button", isOn: self.$alertDisplayed)
                        .frame(height: 30)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .onChange(of: self.showRecordVideoButton, perform: { newValue in
                            self.alertDisplayed = true
                            //                            TelloSettings.showRecordVideoButton = newValue
                        })
                        .onAppear(perform: {
                            self.showRecordVideoButton = TelloSettings.showRecordVideoButton
                        })
                        .alert("$orry", isPresented: self.$alertDisplayed, actions: {
                            Button(action: {
                                self.alertDisplayed = false
                            }, label: {
                                Text("OK")
                            })
                        })
                    Divider()
                        .padding(.horizontal)
                    Toggle("Show Random Flips Button", isOn: self.$showRandomFlipButton)
                        .frame(height: 30)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .onChange(of: self.showRandomFlipButton, perform: { displayRandomFlipsButton in
                            TelloSettings.showRandomFlipButton = displayRandomFlipsButton
                            if TelloSettings.showAllFlipButtons && displayRandomFlipsButton {
                                self.showAllFlipButtons = false
                            }
                        })
                        .onAppear(perform: {
                            self.showRandomFlipButton = TelloSettings.showRandomFlipButton
                        })
                    Spacer()
                    Toggle("Show All Flip Buttons", isOn: self.$showAllFlipButtons)
                        .frame(height: 30)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .onChange(of: self.showAllFlipButtons, perform: { displayAllFlipButtons in
                            TelloSettings.showAllFlipButtons = displayAllFlipButtons
                            if TelloSettings.showRandomFlipButton && displayAllFlipButtons {
                                self.showRandomFlipButton = false
                            }
                        })
                        .onAppear(perform: {
                            self.showAllFlipButtons = TelloSettings.showAllFlipButtons
                        })
                    Spacer()
                }
                .foregroundColor(.white)
                .frame(width: 300, height: 178)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray))
                VStack {
                    SetupInstructions()
                    Divider().frame(width: 300).padding(.horizontal)
                    Button(action: {
                        self.isDisplayed = false
                    }) {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundColor(Color.white)
                            .frame(width: 300, height: 80)
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
