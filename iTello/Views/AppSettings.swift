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
    @AppStorage("showVideoStream") public static var showVideoStream: Bool = true
    @AppStorage("showRandomFlipButton") public static var showRandomFlipButton: Bool = true
    @AppStorage("showAllFlipButtons") public static var showAllFlipButtons: Bool = false
}

struct AppSettings: View {
    
    @Binding var isDisplayed: Bool
    @Binding var setupConnectionDisplayed: Bool
    @State var alertDisplayed: Bool = false
    
    @State var randomFlips: Bool = false
    @State var allFlips: Bool = false

    var body: some View {
        VStack {
            Spacer()
            Section("Video") {
                Toggle("Show Camera Button", isOn: TelloSettings.$showCameraButton)
                    .frame(width: 300, height: 30)
                    .foregroundColor(.white)
                Toggle("Show Record Video Button", isOn: self.$alertDisplayed)
                    .frame(width: 300, height: 30)
                    .foregroundColor(.white)
                    .alert("Sorry, Feature Unavailable", isPresented: self.$alertDisplayed, actions: {
                        Button(action: {
                        }, label: {
                            Text("OK")
                        })
                    })
//                Toggle("Show Video Stream", isOn: TelloSettings.$showVideoStream)
//                    .frame(width: 300, height: 30)
            }
            .foregroundColor(.white)
            Section("Flips") {
                Toggle("Show Random Flip Button", isOn: self.$randomFlips)
                    .foregroundColor(.white)
                    .frame(width: 300, height: 30)
                    .onChange(of: self.randomFlips, perform: { displayRandomFlipsButton in
                        TelloSettings.showRandomFlipButton = displayRandomFlipsButton
                        if TelloSettings.showAllFlipButtons && displayRandomFlipsButton {
                            self.allFlips = false
                        }
                    })
                Toggle("Show All Flip Buttons", isOn: self.$allFlips)
                    .foregroundColor(.white)
                    .frame(width: 300, height: 30)
                    .onChange(of: self.allFlips, perform: { displayAllFlipButtons in
                        TelloSettings.showAllFlipButtons = displayAllFlipButtons
                        if TelloSettings.showRandomFlipButton && displayAllFlipButtons {
                            self.randomFlips = false
                        }
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
