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
    @Binding var displayMediaGallery: Bool
    
    var body: some View {
        VStack {
            Spacer()
            Button(action: {
                self.displayMediaGallery.toggle()
            }, label: {
                Text("Videos")
                    .fontWeight(.semibold)
                    .foregroundColor(Color.telloDark)
                    .frame(width: 300, height: 100)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.telloSilver))
            })
        }
    }
}
