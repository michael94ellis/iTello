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
    @IBOutlet weak var hideCameraSwitch: UISwitch!
    @IBOutlet weak var invertJoySticks: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wifiNameTF.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        wifiNameTF.text = WifiController.shared.telloSSID
        enableVideoSwitch.setOn(TelloSettings.isCameraOn, animated: true)
        showFlipsSwitch.setOn(TelloSettings.showFlips, animated: true)
        speedBoostLabel.text = "Speed Boost: \(TelloSettings.speedBoost)"
        speedBoostSlider.setValue(Float(TelloSettings.speedBoost), animated: true)
        invertJoySticks.setOn(TelloSettings.invertedJoySticks, animated: true)
        hideCameraSwitch.setOn(TelloSettings.isShowingRecordingButtons, animated: true)
    }
    
    // When the user taps the Done/Enter/Return button on the device keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        wifiNameTF.resignFirstResponder()
        if let newSSID = textField.text {
            WifiController.shared.telloSSID = newSSID
        }
        return true
    }
    
    @IBAction func videoEnabledSwitched(_ sender: Any) {
        TelloSettings.isCameraOn.toggle()
        tello?.handleVideoDisplay()
    }
    @IBAction func showFlipButtonsSwitched(_ sender: Any) {
        TelloSettings.showFlips.toggle()
        NotificationCenter.default.post(name: Notification.Name("HideShowFlips"), object: nil)
    }
    @IBAction func hideCameraSwitched(_ sender: UISwitch) {
        TelloSettings.isShowingRecordingButtons.toggle()
        NotificationCenter.default.post(name: Notification.Name("HideCameraButtons"), object: nil)
    }
    @IBAction func speedBoostChanged(_ sender: UISlider) {
        TelloSettings.speedBoost = Int(sender.value)
        speedBoostLabel.text = "Speed Boost: \(Int(sender.value))"
    }
    @IBAction func doneButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    @IBAction func invertJoySticks(_ sender: UISwitch) {
        TelloSettings.invertedJoySticks.toggle()
        NotificationCenter.default.post(name: Notification.Name("InvertJoySticks"), object: nil)
    }
}
