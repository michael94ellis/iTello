//
//  JoyStick.swift
//  oTello
//
//  Created by Michael Ellis on 5/21/20.
//  Copyright © 2020 Mellis. All rights reserved.
//

import UIKit

@IBDesignable
class JoyStick: UIView {
    
    @IBOutlet weak var baseImage: UIImageView!
    @IBOutlet weak var handleImage: UIImageView!
    
    var lastPosition = CGPoint(x: 0, y: 0)
    var centerPosition = CGPoint()
    
    override func touchesBegan(_ touches: (Set<UITouch>?), with event: UIEvent!) {
        // Promote the touched view
        self.superview?.bringSubviewToFront(self)
        
        // Remember original location
        lastPosition = self.center
        centerPosition = self.center
    }
}
