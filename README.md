# iTello, a Tello Drone Controller app for iOS
## Written in SwiftUI
Other Apple Frameworks Used: Network, NetworkExtension, Combine, VideoToolbox, and AVFoundation

If you want to open your DJI Tello Drone controller app and get right to flying you found the right app.

### First time use:
1. Turn on your Tello Drone
2. Identify the WiFi name(SSID) of the Tello, e.g. "TELLO-7J1839"
3. Open the app
4. Tap the WiFi icon and enter the WiFi name into the alert box
5. Connect and Takeoff!

From then on all you need to do is turn on the drone and open the app to tap the WiFi button. Then you'll be connected and ready to fly!

### Features:

* Connect to the Drone's Wifi from inside the app, all you need is the WiFi name!
* Takeoff and Land with the upper corner buttons
* Option Video Stream! Don't use extra battery and processing power if you don't want to
* Flip buttons let you identify which type of flip you are performing
* More to come!

Be careful, please do not fly over water, in windy conditions, or too close to your loved ones faces or you may lose your drone.

### Watch a Demo on Youtube
[![Demo of iTello](https://img.youtube.com/vi/eHCie0C5SJU/0.jpg)](https://www.youtube.com/watch?v=eHCie0C5SJU)

## Contribute
If you're interested please reach out to know how to help or make a PR!



# TODO:

 * Design
   - Better connection screen and "loading" animation for button
   - Better looking joysticks
   - Better controller screen
     * Joysticks should be appropriate size for screen size
     * What to do with Battery/State info? What about setting window popup buttons?
     * Takeoff/land buttons need to be something other than play and pause 
     * Add the flip buttons back
       - Random Flip Button
       - All 4 Flip Buttons
 
 * Settings
   - Add ability to toggle camera
   - Adjutable joystick visibility
   - Adjustable joystick origin point(fixed or where use taps first)
   - Add ability to show flip buttons
     * Random Flip Button
     * All 4 Flip Buttons
 
 * Videos/Pictures
   - Figure out why Video asset won't save to camera roll
   - Show the photos in a gallery in the app
   - In App Purchase for the video saving feature
 
 * Refactoring
   - Cleanup Video Processing Code and make it testable
   - Combine the UDP Listener and UDP Client
   - (Low Priority) Cleanup SwiftUIJoystick Package
