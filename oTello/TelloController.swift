//
//  TelloController.swift
//  HelloTello
//
//  Swift Class to interact with the DJI/Ryze Tello drone using the official Tello api.
//  Tello API documentation:
//  https://dl-cdn.ryzerobotics.com/downloads/tello/20180910/Tello%20SDK%20Documentation%20EN_1.3.pdf
//

import VideoToolbox
import SwiftSocket

/// This Swift object can control a DJI Tello drone and also decode and display it's video stream
class TelloController: NSObject, VideoFrameDecoderDelegate {
    /// Amount of time between each movement broadcast to prevent getting spam-bocked by the drone
    private let commandDelay = 0.1
    /// Speed of Up/Down movement
    var upDown = 0
    /// Speed of Left/Right movement
    var leftRight = 0
    /// Speed of Forward/Back movement
    var forwardBack = 0
    /// Speed of movement Clockwise or CounterClockwise
    var yaw = 0
    /// rc l/r f/b u/d yaw
    private var moveCommand: String { "rc \(self.leftRight + Tello.speedBoost) \(self.forwardBack + Tello.speedBoost) \(self.upDown + Tello.speedBoost) \(self.yaw + Tello.speedBoost)" }
    /// Prevents too many movement commands from being issued at once
    private var moveTimer = Timer()
    
    // MARK: - Stream Data Vars
    
    private var responseWaiter = Timer()
    /// Last known battery amount received from tello
    var battery = ""
    /// Last known Signal to Noise ratio for WiFi received from tello
    var wifi = ""
    var isInCommandMode = false
    private lazy var videoDecoder = VideoFrameDecoder()
    /// A reference to the image view where the video will be displayed
    var videoView: UIImageView?
    // Listeners
    private var videoStreamServer = UDPServer(address: Tello.ResponseIPAddress, port: Tello.VideoStreamPort)
    private var stateStreamServer = UDPServer(address: Tello.ResponseIPAddress, port: Tello.StatePort)
    // Broadcaster
    private var commandBroadcaster = UDPClient(address: Tello.IPAddress, port: Tello.CommandPort)
    
    override init() {
        super.init()
        receiveCommandResponseStream()
        receiveStateStream()
        VideoFrameDecoder.delegate = self
        repeatCommandForResponse(for: CMD.on)
        if Tello.isCameraOn {
            repeatCommandForResponse(for: CMD.streamOn)
            displayVideoStream()
        }
    }
    private var commandRepeatMax = 4
    /// Repeats a comment until an `ok` is received from the Tello
    private func repeatCommandForResponse(for command: String) {
        responseWaiter = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            if !self.isInCommandMode, self.commandRepeatMax > 0 {
                self.sendCommand(command)
                self.commandRepeatMax -= 1
            } else {
                self.responseWaiter.invalidate()
                self.commandRepeatMax = 4
            }
        }
    }
    
    // MARK: - Tello Command Methods
    
    func takeOff() {
        self.sendCommand(CMD.takeOff)
    }
    /// Can sometimes be ignored, especially if within first 5 seconds or so of flight time
    func land() {
        repeatCommandForResponse(for: CMD.land)
    }
    /// EMERGENCY STOP, drone motors will cease immediately, should not always be viasible to user
    func emergencyLand() {
        self.sendCommand(CMD.off)
    }
    /// See the FLIP enum for list of available flip directions
    func flip(_ direction: FLIP) {
        self.sendCommand(direction.commandValue)
    }
    /// Handles continuous movement events from the Joysticks, limiting output commands to once per `commandDelay`
    func updateMovementTimer() {
        if moveTimer.isValid { return }
        moveTimer = Timer.scheduledTimer(withTimeInterval: commandDelay, repeats: true) { _ in
            // Concatenate the 4 int values and compare to 0 using bitwise operator AND(&)
            if self.leftRight & self.forwardBack & self.upDown & self.yaw == 0 {
                // The joysticks go back to 0 when the user lets go, therefore if the value isnt 0
                // Send an extra because UDP packets can be lost
                self.sendCommand(self.moveCommand)
                self.moveTimer.invalidate()
            }
            // Send 2 because UDP packets can be lost
            self.sendCommand(self.moveCommand)
            self.sendCommand(self.moveCommand)
        }
    }
    
    @discardableResult
    private func sendCommand(_ command: String) -> Result {
        print("Sending Command: \(command)")
        return commandBroadcaster.send(string: command)
    }
    
    /// Called by the UI to toggle the camera state
    func toggleCamera() {
        // command tello to stream video
        let videoStreamCommand = Tello.isCameraOn ? CMD.streamOn : CMD.streamOff
        self.sendCommand(videoStreamCommand)
        guard Tello.isCameraOn else { return }
        displayVideoStream()
    }
    /// Listens to the video stream broadcast from the drone
    private func displayVideoStream() {
        DispatchQueue.global(qos: .userInteractive).async {
            /// Video data is stored and processed in this variable as it is received
            var videoFrameBuffer: [Byte] = []
            // When user toggles camera this will cease
            while Tello.isCameraOn {
                // Begin receiving video data
                let (data, _, _) = self.videoStreamServer.recv(2048)
                // No frame is a full image, they must be received separately and assembled
                self.handleVideoStream(frameBuffer: &videoFrameBuffer, data: data)
            }
        }
    }
    /// Passes the received frame data to the video decoder
    private func handleVideoStream(frameBuffer: inout [Byte], data: FrameData?) {
        if let videoStreamData = data {
            // Combine previous buffer with current buffer
            frameBuffer = frameBuffer + videoStreamData
            // Check received NALU data for size validity
            if videoStreamData.count < 1460,
                frameBuffer.count > 40 {
                // Update video frame
                videoDecoder.interpretRawFrameData(&frameBuffer)
                // Refresh the received data buffer to begin processing a new frame
                frameBuffer = []
            }
        }
    }
    /// Read data from the ongoing STATE stream
    private func receiveStateStream() {
        DispatchQueue.global(qos: .userInteractive).async {
            let (data, _, _) = self.stateStreamServer.recv(2048)
            if let stateStreamData = data,
                let stateString = String(bytes: stateStreamData, encoding: .utf8) {
                let stateValues = stateString.split(separator: ";")
                if let batteryLevel = stateValues.first(where: { $0.hasPrefix("bat") }) {
                    self.battery = batteryLevel.split(separator: ":").last?.description ?? ""
                }
            }
            self.receiveStateStream()
        }
    }
    /// Read data from the ongoing STATE stream
    private func receiveCommandResponseStream() {
        DispatchQueue.global(qos: .userInteractive).async {
            while true {
                let (data, _, _) = self.commandBroadcaster.recv(2048)
                if let responseData = data,
                    let response = String(bytes: responseData, encoding: .utf8) {
                    print("Command Response: \(response)")
                    if response == "ok", !self.isInCommandMode {
                        self.isInCommandMode = true
                    }
                }
            }
        }
    }
    /// This is called when the VideoFrameDecoder finishes decoding a frame
    func receivedDisplayableFrame(_ frame: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(frame, options: nil, imageOut: &cgImage)
        guard let displayableImage = cgImage else {
            print("Failed to decode a frame")
            return
        }
        DispatchQueue.main.async {
            // Update video image with new frame
            self.videoView?.image = UIImage(cgImage: displayableImage)
//            let ciImage = CIImage(cgImage: displayableImage)
//            self.findFaces(in: ciImage)
        }
        
    }
    
    var faceBox: CGRect?
    
    func findFaces(in image: CIImage) {
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)!
        
        let faces = faceDetector.features(in: image)
        
        if let face = faces.first as? CIFaceFeature {
            print("Found face at \(face.bounds)")
            if !face.hasRightEyePosition {
                print("i think i should go counter clockwise")
            } else if !face.hasLeftEyePosition {
                print("i think i should go clockwise")
            }
            if let lastFaceBox = faceBox {
                if lastFaceBox.size.magnitude > face.bounds.size.magnitude + 50 {
                    print("i think i should move back")
                } else if lastFaceBox.size.magnitude < face.bounds.size.magnitude - 50 {
                    print("i think i should move forward")
                }
            }
            faceBox = face.bounds
        }
    }
}

extension CGSize: Comparable {
    
    public var magnitude: CGFloat { height * width }
    
    public static func < (lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.magnitude < rhs.magnitude
    }
}
