//
//  MediaGalleryButton.swift
//  iTello
//
//  Created by Michael Ellis on 12/24/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

struct MediaGalleryButton: View {
    
    @EnvironmentObject var telloStore: TelloStoreViewModel
    @State var displayUnavailableMessage: Bool = false
    @State var alertDisplayed: Bool = false
    
    var body: some View {
        VStack {
            Text(self.displayUnavailableMessage ? "Camera Button will save to photo gallery" : "")
                .font(.callout)
                .foregroundColor(Color.white)
                .frame(height: 25)
            Spacer()
            Button(action: {
                if self.telloStore.hasPurchasedRecording {
                    
                }
                self.displayUnavailableMessage.toggle()
                self.alertDisplayed = true
            }, label: {
                Text("Videos")
                    .fontWeight(.semibold)
                    .foregroundColor(Color.telloDark)
                    .frame(width: 300, height: 100)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.telloSilver))
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
                        self.telloStore.purchaseVideoRecording()
                    }, label: {
                        Text("OK")
                    })
                })
            Spacer()
        }
    }
}
