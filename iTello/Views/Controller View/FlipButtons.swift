//
//  FlipButtons.swift
//  iTello
//
//  Created by Michael Ellis on 12/29/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

struct FlipButtons: View {
    
    var tello: TelloController
    @AppStorage("showFlipButtons") public var showFlipButtons: Int = 0
    
    private let flipImageNames = ["arrow.uturn.forward",
                                  "arrow.uturn.up",
                                  "arrow.uturn.down",
                                  "arrow.uturn.backward"]
    @State var randomFlipImage: String = "arrow.uturn.forward"
    
    @ViewBuilder func flipButton(for flip: FLIP, imageName: String) -> some View {
        Button(action: {
            self.tello.flip(flip)
        }) {
            Image(systemName: imageName).resizable()
                .foregroundColor(.telloBlue)
                .frame(width: 45, height: 45)
        }
        .frame(width: 70, height: 70)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder func randomFlipButton() -> some View {
        Button(action: {
            let newIndex = Int.random(in: 0...3)
            self.randomFlipImage = self.flipImageNames[newIndex]
            self.tello.flip(FLIP.all[newIndex])
        }) {
            Image(systemName: self.randomFlipImage).resizable()
                .foregroundColor(.telloBlue)
                .frame(width: 45, height: 45)
        }
        .frame(width: 70, height: 70)
        .contentShape(Rectangle())
    }
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if self.showFlipButtons == 2 {
                    ForEach(0...3, id: \.self) { index in
                        self.flipButton(for: FLIP.all[index], imageName: self.flipImageNames[index])
                    }
                } else if self.showFlipButtons == 1 {
                    self.randomFlipButton()
                }
                Spacer()
            }
            .padding(.bottom, 20)
        }
    }
}
