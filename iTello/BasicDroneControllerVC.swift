//
//  BasicDroneControllerVC.swift
//  oTello
//
//  Created by Michael Ellis on 5/19/20.
//  Copyright © 2020 Mellis. All rights reserved.
//

import UIKit

class BasicDroneControllerVC: UIViewController {
    
    /// When this object is nil it means there is no connection to a drone
    var tello: TelloController? {
        didSet {
            // the wifi label and button become disabled while a connection is being made
            self.wifiLabel.textColor = .label
        }
    }
    /// Updates the data variables on the UI if a Tello is connected
    var telloDataReadTimer = Timer()
    /// Used to determine if user is spamming takeoff, which indicates a problem, and a popup message is shown
    var takeoffSpamDetectionTimer = Timer()
    /// Used to determine if user is spamming the land button, which indicates a problem, and an emergency land button will appear
    var landingSpamDetectionTimer = Timer()
    /// Will be reset when the tap timer expires
    var takeoffTapCount = 0
    /// Will be reset when the tap timer expires
    var landingTapCount = 0
    
    @IBOutlet weak var rightJoyStick: JoyStick!
    @IBOutlet weak var leftJoyStick: JoyStick!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var photoButton: UIStackView!
    @IBOutlet weak var videoImage: UIImageView!
    @IBOutlet weak var wifiButton: UIButton!
    @IBOutlet weak var wifiLabel: UILabel!
    @IBOutlet weak var batteryLabel: UILabel!
    @IBOutlet weak var takeOffButton: UIButton!
    @IBOutlet weak var emergencyLandButton: UIButton!
    @IBOutlet weak var emergencyLandLabel: UILabel!
    @IBOutlet weak var flip1: UIButton!
    @IBOutlet weak var flip2: UIButton!
    @IBOutlet weak var flip3: UIButton!
    @IBOutlet weak var flip4: UIButton!
    
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
            self.batteryLabel.text = "Battery: \(tello.battery)%"
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(hideFlips), name: Notification.Name("HideShowFlips"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideCameraButtons), name: Notification.Name("HideCameraButtons"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(invertJoySticks), name: Notification.Name("InvertJoySticks"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.emergencyLandLabel.isHidden = true
        self.emergencyLandButton.isHidden = true
        self.photoButton.isHidden = TelloSettings.isShowingRecordingButtons
        if let currentSSID = WifiController.shared.wifiConnectionInfo()?["SSID"] as? String,
            currentSSID.hasPrefix("TELLO-") {
            self.handleWiFiConnectionSuccess(ssid: currentSSID)
        } else {
            firstOpenDialog()
        }
        hideFlips()
    }
    
    /// Presented to the user if they just opened the app, it detects this by using the default telloSSID value `TELLO-`
    /// Example SSID: `TELLO-5C8145`
    func firstOpenDialog() {
        if WifiController.shared.telloSSID == "TELLO-" {
            let welcomeAlert = UIAlertController(
                title: "Welcome",
                message: "Please turn on your Tello and wait for it to flash yellow.\n\nThen tap the WiFi or Gear icon to set the WiFi name and connect!",
                preferredStyle: .alert)
            welcomeAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(welcomeAlert, animated: true, completion: nil)
        }
    }
    
    private func adjustJoyStickValue(_ value: Int, speed: Int) -> Int {
        if value < 0 {
            return value - speed
        } else if value > 0 {
            return value + speed
        } else {
            return 0
        }
    }
    
    func setupLeftJoystick() {
        // Transparency
        leftJoyStick.baseAlpha = 0.15
        leftJoyStick.handleAlpha = 0.3
        leftJoyStick.monitor = .xy(monitor: { value in
            guard let tello = self.tello else { return }
            let x = Int(value.x)
            let y = Int(value.y)
            tello.yaw = self.adjustJoyStickValue(x, speed: TelloSettings.speedBoost)
            tello.upDown = self.adjustJoyStickValue(y, speed: TelloSettings.speedBoost)
            tello.updateMovementTimer()
        })
    }
    
    func setupRightJoystick() {
        // Transparency
        rightJoyStick.baseAlpha = 0.15
        rightJoyStick.handleAlpha = 0.3
        rightJoyStick.monitor = .xy(monitor: { value in
            guard let tello = self.tello else { return }
            let x = Int(value.x)
            let y = Int(value.y)
            tello.leftRight = self.adjustJoyStickValue(x, speed: TelloSettings.speedBoost)
            tello.forwardBack = self.adjustJoyStickValue(y, speed: TelloSettings.speedBoost)
            tello.updateMovementTimer()
        })
    }
    
    @IBAction func wifiButtonTapped(_ sender: UIButton) {
        var wifiAlertTitle = "Connect to WiFi"
        var wifiMessage = "Enter the Tello's WiFi Name(SSID)"
        var buttonText = "Connect"
        let savedSSID = WifiController.shared.telloSSID
        
        // Change message if user is already connected
        if let currentSSID = WifiController.shared.wifiConnectionInfo()?["SSID"] as? String,
            currentSSID.hasPrefix("TELLO-") {
            // Currently connected to some TELLO drone's WiFi
            wifiAlertTitle = "Reconnect?"
            wifiMessage = "Enter the Tello's WiFi Name(SSID)"
            buttonText = "Reconnect"
        }
        presentWiFiDialog(title: wifiAlertTitle, message: wifiMessage, buttonText: buttonText, savedSSID: savedSSID)
    }
    
    func presentWiFiDialog(title: String, message: String, buttonText: String, savedSSID: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = savedSSID
        }
        alert.addAction(UIAlertAction(title: buttonText, style: .default, handler: { _ in
            let textField = alert.textFields?[0]
            guard let newSSID = textField?.text, !newSSID.isEmpty else {
                self.wifiLabel.text = "Invalid SSID"
                return
            }
            if newSSID != savedSSID {
                WifiController.shared.telloSSID = newSSID
            }
            self.connectToDroneWiFi(ssid: newSSID)
            print("Connecting to WiFi SSID: \(textField?.text ?? "error")")
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func connectToDroneWiFi(ssid: String) {
        // Attempt to use NEHotspot to connect to the drone
        self.wifiLabel.textColor = .lightText
        WifiController.shared.connectTo(ssid: ssid) { success in
            guard success else {
                self.wifiButton.setBackgroundImage(self.wifiExclamationImage, for: .normal)
                self.wifiLabel.text = "Not Connected"
                self.tello = nil
                return
            }
            self.handleWiFiConnectionSuccess(ssid: ssid)
        }
    }
    
    /// Opens the settings menu
    @IBAction func settingsButtonTapped(_ sender: Any) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let settingsPage = storyBoard.instantiateViewController(withIdentifier: "settingsVC") as! SettingsViewController
        settingsPage.tello = self.tello
        self.present(settingsPage, animated: true, completion: nil)
    }
    
    /// Sets the label at the top of the view
    func handleWiFiConnectionSuccess(ssid: String) {
        self.wifiLabel.text = ssid
        self.wifiButton.setBackgroundImage(self.wifiImage, for: .normal)
        self.tello = TelloController()
        self.tello?.videoView = self.videoImage
    }
    
    @IBAction func photoButtonTapped(_ sender: Any) {
        self.tello?.takePhoto()
    }
    
    // MARK: - Drone Command Buttons
    
    /// Tell the drone to takeoff
    @IBAction func takeoff(_ sender: UIButton) {
        // If there is a timer it means the button was just tapped
        if takeoffSpamDetectionTimer.isValid {
            // The timer has been started, count the taps
            takeoffTapCount += 1
            // When 3 taps happen end the timer and show the secondary action
            if takeoffTapCount >= 3 {
                takeoffSpamDetectionTimer.invalidate()
                self.takeoffTapCount = 0
                self.presentWiFiDialog(
                    title: "Connection Issue?",
                    message: "It seems like you may need to reconnect",
                    buttonText: "Connect",
                    savedSSID: WifiController.shared.telloSSID)
            }
        } else {
            // Begin the timer
            takeoffSpamDetectionTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                self.takeoffTapCount = 0
            }
        }
        tello?.takeOff()
    }
    @IBAction func emergencyLand(_ sender: Any) {
        tello?.emergencyLand()
    }
    /// Attempt to land the drone, it may need extra taps. If extra taps are sensed the Emergency Stop option is show
    @IBAction func land(_ sender: UIButton) {
        // If there is a timer it means the button was just tapped
        if landingSpamDetectionTimer.isValid {
            guard self.emergencyLandButton.isHidden,
                self.emergencyLandLabel.isHidden else {
                    return
            }
            // The timer has been started, count the taps
            landingTapCount += 1
            // When 3 taps happen end the timer and show the secondary action
            if landingTapCount >= 3 {
                landingSpamDetectionTimer.invalidate()
                self.landingTapCount = 0
                self.emergencyLandLabel.isHidden = false
                self.emergencyLandButton.isHidden = false
                landingSpamDetectionTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in
                    self.emergencyLandLabel.isHidden = true
                    self.emergencyLandButton.isHidden = true
                }
            }
        } else {
            // Begin the timer
            landingSpamDetectionTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                self.landingTapCount = 0
                self.emergencyLandLabel.isHidden = true
                self.emergencyLandButton.isHidden = true
            }
        }
        tello?.land()
    }
    
    /// Flips are major gimmick, so they don't need to be shown
    @objc func hideCameraButtons() {
        photoButton.isHidden = TelloSettings.isShowingRecordingButtons
    }
    
    /// Flips are major gimmick, so they don't need to be shown
    @objc func hideFlips() {
        flip1.isHidden = TelloSettings.showFlips
        flip2.isHidden = TelloSettings.showFlips
        flip3.isHidden = TelloSettings.showFlips
        flip4.isHidden = TelloSettings.showFlips
    }
    /// Invert the controls for video game like usage
    @objc func invertJoySticks() {
        let temp = leftJoyStick
        leftJoyStick = rightJoyStick
        rightJoyStick = temp
        setupLeftJoystick()
        setupRightJoystick()
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

