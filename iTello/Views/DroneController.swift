//
//  DroneController.swift
//  iTello
//
//  Created by Michael Ellis on 12/7/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

struct DroneController: View {
    
    @Binding var displaySettings: Bool
    
    var body: some View {
        GeometryReader { parent in
            VStack {
                HStack {
                    Button(action: {
                        
                    }) {
                        Image(systemName: "play.fill").resizable()
                    }
                    .frame(width: parent.size.width / 15, height: parent.size.width / 15)
                    .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                    .contentShape(Rectangle())
                    .padding(.leading,  parent.size.width / 15)
                    Spacer(minLength: parent.size.width / 6)
                    Button(action: {
                        self.displaySettings.toggle()
                    }, label: {
                        Image(systemName: "gearshape")
                        Text("Connection")
                            .font(.body)
                    })
                        .frame(height: parent.size.height / 20)
                    Spacer(minLength: parent.size.width / 6)
                    Button(action: {
                        
                    }) {
                        Image(systemName: "pause.fill").resizable()
                    }
                    .frame(width: parent.size.width / 15, height: parent.size.width / 15)
                    .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                    .contentShape(Rectangle())
                    .padding(.trailing, parent.size.width / 15)
                }
                .padding(.top, 30)
                Spacer()
                HStack {
                    Joystick(width: parent.size.width / 4)
                        .padding(.leading, parent.size.width / 10)
                        .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                    Spacer()
                    Joystick(width: parent.size.width / 4)
                        .padding(.trailing, parent.size.width / 10)
                        .shadow(color: .darkEnd, radius: 3, x: 1, y: 2)
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
