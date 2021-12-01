//
//  iTelloApp.swift
//  iTello
//
//  Created by Michael Ellis on 11/14/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI

@main
struct iTelloApp: App {
    
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
//            GeometryReader { parent in
//                // Main Container
//                VStack {
//                    Spacer()
                    HStack {
                        ContentView()
                        ContentView()
                    }
//                    Spacer()
//                }
//                .frame(width: parent.size.width, height: parent.size.height)
//            }
        }
    }
}
 
extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow((point.x - x), 2) + pow((point.y - y), 2))
    }
}

struct ContentView: View {

    @State private var position = CGPoint(x: 100, y: 100)
    private var dragDiametr: CGFloat = 200.0
    var body: some View {

    return
        VStack{
            Text("current position = (x: \(Int(position.x)), y: \(Int(position.y)))")
            Circle()
              .fill(Color.red)
              .frame(width: dragDiametr, height: dragDiametr)
              .overlay(
                Circle()
                  .fill(Color.black)
                  .frame(width: dragDiametr / 4, height: dragDiametr / 4)
                  .position(x: position.x, y: position.y)
                  .gesture(DragGesture()
                  .onChanged(){value in
                    let currentLocation = value.location
                    let center = CGPoint(x: self.dragDiametr/2, y: self.dragDiametr/2)
                    let distance = center.distance(to:currentLocation)
                    if distance > self.dragDiametr / 2 {
                        let k = (self.dragDiametr / 2) / distance
                        let newLocationX = (currentLocation.x - center.x) * k+center.x
                        let newLocationY = (currentLocation.y - center.y) * k+center.y
                        self.position = CGPoint(x: newLocationX, y: newLocationY)
                    }else{
                        self.position = value.location
                    }
                  })
              )
        }
    }
}
