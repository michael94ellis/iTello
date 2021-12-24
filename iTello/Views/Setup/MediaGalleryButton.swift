//
//  MediaGalleryButton.swift
//  iTello
//
//  Created by Michael Ellis on 12/24/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

struct MediaGalleryButton: View {
    
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
                self.displayUnavailableMessage.toggle()
                self.alertDisplayed = true
            }, label: {
                Text("Videos")
                    .fontWeight(.semibold)
                    .foregroundColor(Color.white)
                    .frame(width: 300, height: 100)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray))
            })
            .alert("$orry", isPresented: self.$alertDisplayed, actions: {
                Button(action: {
                    self.alertDisplayed = false
                }, label: {
                    Text("OK")
                })
            })
            Spacer()
        }
    }
}
