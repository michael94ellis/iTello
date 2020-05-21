//
//  BasicDroneControllerVC.swift
//  oTello
//
//  Created by Michael Ellis on 5/19/20.
//  Copyright © 2020 Mellis. All rights reserved.
//

import UIKit
import BRHJoyStickView

class BasicDroneControllerVC: UIViewController {
    
    /// When this object is nil it means there is no connection to a drone
    var tello: TelloController? {
        didSet {
            // the wifi label and button become disabled while a connection is being made
            self.wifiLabel.textColor = .label
            self.wifiButton.isEnabled.toggle()
        }
    }
    /// Updates the data variables on the UI if a Tello is connected
    var telloDataReadTimer = Timer()
    
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var videoImage: UIImageView!
    @IBOutlet weak var leftJoystick: JoyStickView!
    @IBOutlet weak var rightJoystick: JoyStickView!
    @IBOutlet weak var wifiButton: UIButton!
    @IBOutlet weak var wifiLabel: UILabel!
    @IBOutlet weak var batteryLabel: UILabel!
    
    // Store these images for easy access
    lazy var wifiImage = UIImage(systemName: "wifi")
    lazy var wifiDisconnectedImage = UIImage(systemName: "wifi.slash")
    lazy var wifiExclamationImage = UIImage(systemName: "wifi.exclamationmark")
    
    lazy var videoEnabledImage = UIImage(systemName: "video.fill")
    lazy var videoDisabledImage = UIImage(systemName: "video.slash.fill")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: Add Settings Page
        // TODO: Make controller based on touchDown and xy drag distance from touchdown
        // TODO: fullscreen video mode option
        setupLeftJoystick()
        setupRightJoystick()
        telloDataReadTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            guard let tello = self.tello else { return }
            self.batteryLabel.text = "Battery: \(tello.battery)"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firstOpenDialog()
    }
    
    /// Presented to the user if they just opened the app, it detects this by using the default telloSSID value `TELLO-`
    /// Example SSID: `TELLO-5C8145`
    func firstOpenDialog() {
        if WifiController.shared.telloSSID == "TELLO-" {
            let welcomeAlert = UIAlertController(
                title: "Welcome",
                message: "Please turn on the drone and wait a moment for it to prepare.\nThen tap the WiFi icon to set the WiFi name and connect!",
                preferredStyle: .alert)
            welcomeAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(welcomeAlert, animated: true, completion: nil)
        }
    }
    
    func setupLeftJoystick() {
        // Transparency
        leftJoystick.baseAlpha = 0.15
        leftJoystick.handleAlpha = 0.3
        leftJoystick.monitor = .xy(monitor: { value in
            guard let tello = self.tello else { return }
            tello.yaw = Int(value.x)
            tello.upDown = Int(value.y)
            tello.updateMovementTimer()
        })
    }
    
    func setupRightJoystick() {
        // Transparency
        rightJoystick.baseAlpha = 0.15
        rightJoystick.handleAlpha = 0.3
        rightJoystick.monitor = .xy(monitor: { value in
            guard let tello = self.tello else { return }
            tello.leftRight = Int(value.x)
            tello.forwardBack = Int(value.y)
            tello.updateMovementTimer()
        })
    }
    @IBAction func connectWiFi(_ sender: UIButton) {
        let currentSSID = WifiController.shared.telloSSID
        let alert = UIAlertController(title: "Connect to WiFi",
                                      message: "Enter the Tello's WiFi Name(SSID)",
                                      preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = currentSSID
        }
        alert.addAction(UIAlertAction(title: "Connect", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields?[0]
            guard let newSSID = textField?.text, !newSSID.isEmpty else {
                self.wifiLabel.text = "Invalid SSID"
                return
            }
            print("Connecting to WiFi SSID: \(textField?.text ?? "error")")
            if newSSID != currentSSID {
                WifiController.shared.telloSSID = newSSID
            }
            self.wifiLabel.textColor = .lightText
            self.wifiButton.isEnabled.toggle()
            WifiController.shared.connectTo(ssid: newSSID) { success in
                if success {
                    self.wifiLabel.text = newSSID
                    self.wifiButton.setBackgroundImage(self.wifiImage, for: .normal)
                    self.tello = TelloController()
                    self.tello?.videoView = self.videoImage
                } else {
                    self.wifiButton.setBackgroundImage(self.wifiExclamationImage, for: .normal)
                    self.wifiLabel.text = "Not Connected"
                    self.tello = nil
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Drone Command Buttons
    
    /// This ought to not work if there is no Drone connected
    @IBAction func videoButtonTapped(_ sender: Any) {
        tello?.toggleCamera()
        let isVideoEnabled = tello?.isCameraOn ?? false
        videoButton.setBackgroundImage(isVideoEnabled ? videoEnabledImage : videoDisabledImage, for: .normal)
    }
    
    /// Tell the drone to takeoff
    @IBAction func takeoff(_ sender: UIButton) {
        tello?.takeOff()
    }
    /// Attempt to land the drone, it may need extra taps
    @IBAction func land(_ sender: UIButton) {
        tello?.land()
    }
    /// Backflip
    @IBAction func flipA(_ sender: Any) {
        tello?.flip(.b)
    }
    /// Rightflip
    @IBAction func flipB(_ sender: Any) {
        tello?.flip(.r)
    }
    /// Frontflip
    @IBAction func flipC(_ sender: Any) {
        tello?.flip(.f)
    }
    /// Leftflip
    @IBAction func flipD(_ sender: Any) {
        tello?.flip(.l)
    }
}

