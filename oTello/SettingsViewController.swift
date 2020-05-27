//
//  SettingsViewController.swift
//  oTello
//
//  Created by Michael Ellis on 5/27/20.
//  Copyright © 2020 Mellis. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITextFieldDelegate {
    
    public var tello: TelloController?
    
    @IBOutlet weak var wifiNameTF: UITextField!
    @IBOutlet weak var enableVideoSwitch: UISwitch!
    @IBOutlet weak var speedBoostLabel: UILabel!
    @IBOutlet weak var speedBoostSlider: UISlider!
    @IBOutlet weak var showFlipsSwitch: UISwitch!
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wifiNameTF.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        wifiNameTF.text = WifiController.shared.telloSSID
        enableVideoSwitch.setOn(Tello.isCameraOn, animated: true)
        showFlipsSwitch.setOn(Tello.showFlips, animated: true)
        speedBoostLabel.text = "Speed Boost: \(Tello.speedBoost)"
        speedBoostSlider.setValue(Float(Tello.speedBoost), animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        wifiNameTF.resignFirstResponder()
        if let newSSID = textField.text {
            WifiController.shared.telloSSID = newSSID
        }
        return true
    }
    
    @IBAction func videoEnabledSwitched(_ sender: Any) {
        Tello.isCameraOn.toggle()
        tello?.toggleCamera()
    }
    @IBAction func showFlipButtonsSwitched(_ sender: Any) {
        Tello.showFlips.toggle()
        NotificationCenter.default.post(name: Notification.Name("HideShowFlips"), object: nil)
    }
    @IBAction func speedBoostChanged(_ sender: Any) {
        Tello.speedBoost = Int(speedBoostSlider.value)
        speedBoostLabel.text = "Speed Boost: \(Int(speedBoostSlider.value))"
    }
    @IBAction func doneButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
