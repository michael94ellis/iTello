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
    @Binding var setupConnectionDisplayed: Bool
    @State var alertDisplayed: Bool = false
    @State var showCameraButton = true
    @State var showRecordVideoButton = false
    @State var showVideoStream = true
    @State var showRandomFlipButton = true
    @State var showAllFlipButtons = false

    var body: some View {
        VStack {
            Spacer()
            Section("Video") {
                Toggle("Show Camera Button", isOn: self.$showCameraButton)
                    .frame(width: 300, height: 30)
                    .foregroundColor(.white)
                    .onChange(of: self.showCameraButton, perform: { newValue in
                        TelloSettings.showCameraButton = newValue
                    })
                    .onAppear(perform: {
                        self.showCameraButton = TelloSettings.showCameraButton
                    })
                Toggle("Show Record Video Button", isOn: self.$showRecordVideoButton)
                    .frame(width: 300, height: 30)
                    .foregroundColor(.white)
                    .onChange(of: self.showRecordVideoButton, perform: { newValue in
                        TelloSettings.showRecordVideoButton = newValue
                    })
                    .onAppear(perform: {
                        self.showRecordVideoButton = TelloSettings.showRecordVideoButton
                    })
                    .alert("Sorry, Feature Unavailable", isPresented: self.$alertDisplayed, actions: {
                        Button(action: {
                        }, label: {
                            Text("OK")
                        })
                    })
            }
            .foregroundColor(.white)
            Section("Flips") {
                Toggle("Show Random Flip Button", isOn: self.$showRandomFlipButton)
                    .foregroundColor(.white)
                    .frame(width: 300, height: 30)
                    .onChange(of: self.showRandomFlipButton, perform: { displayRandomFlipsButton in
                        TelloSettings.showRandomFlipButton = displayRandomFlipsButton
                        if TelloSettings.showAllFlipButtons && displayRandomFlipsButton {
                            self.showAllFlipButtons = false
                        }
                    })
                    .onAppear(perform: {
                        self.showRandomFlipButton = TelloSettings.showRandomFlipButton
                    })
                Toggle("Show All Flip Buttons", isOn: self.$showAllFlipButtons)
                    .foregroundColor(.white)
                    .frame(width: 300, height: 30)
                    .onChange(of: self.showAllFlipButtons, perform: { displayAllFlipButtons in
                        TelloSettings.showAllFlipButtons = displayAllFlipButtons
                        if TelloSettings.showRandomFlipButton && displayAllFlipButtons {
                            self.showRandomFlipButton = false
                        }
                    })
                    .onAppear(perform: {
                        self.showAllFlipButtons = TelloSettings.showAllFlipButtons
                    })
            }
            .foregroundColor(.white)
            HStack {
                Button(action: {
                    self.isDisplayed = false
                    self.setupConnectionDisplayed = true
                }) {
                    Text("Drone Connection")
                        .fontWeight(.semibold)
                        .foregroundColor(Color(UIColor.label))
                        .frame(width: 200, height: 40)
                }
                .background(RoundedRectangle(cornerRadius: 4)
                                .fill(Color(UIColor.lightGray))
                                .shadow(color: Color.darkStart, radius: 2, x: 1, y: 2))
                .contentShape(Rectangle())
                
                Button(action: {
                    self.isDisplayed = false
                    self.setupConnectionDisplayed = false
                }) {
                    Text("Done")
                        .fontWeight(.semibold)
                        .foregroundColor(Color(UIColor.label))
                        .frame(width: 200, height: 40)
                }
                .background(RoundedRectangle(cornerRadius: 4)
                                .fill(Color(UIColor.lightGray))
                                .shadow(color: Color.darkStart, radius: 2, x: 1, y: 2))
                .contentShape(Rectangle())
            }
            Spacer()
            Button(action: {
                sendLogs()
            }) {
                Text("Problems? Send Logs")
                    .fontWeight(.semibold)
                    .foregroundColor(Color(uiColor: .systemBlue))
                    .padding(8)
            }
            .contentShape(Rectangle())
            .padding(.bottom, 25)
        }
    }
}
