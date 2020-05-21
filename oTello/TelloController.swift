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
    private var moveCommand: String { "rc \(self.leftRight) \(self.forwardBack) \(self.upDown) \(self.yaw)" }
    /// Prevents too many movement commands from being issued at once
    private var moveTimer = Timer()
    
    // MARK: - Stream Data Vars
    
    /// Last known battery amount received from tello
    var battery = ""
    /// Last known Signal to Noise ratio for WiFi received from tello
    var wifi = ""
    var isCameraOn = false
    private lazy var videoDecoder = VideoFrameDecoder()
    /// A reference to the image view where the video will be displayed
    var videoView: UIImageView?
    // Listeners
    private var videoStreamServer = UDPServer(address: Tello.ResponseIPAddress, port: Tello.VideoStreamPort)
    private var stateStreamServer = UDPServer(address: Tello.ResponseIPAddress, port: Tello.StatePort)
    private var commandResponseServer = UDPServer(address: Tello.ResponseIPAddress, port: Tello.StatePort)
    // Broadcaster
    private var commandBroadcaster = UDPClient(address: Tello.IPAddress, port: Tello.CommandPort)
    
    override init() {
        super.init()
        receiveCommandResponseStream()
        receiveStateStream()
        VideoFrameDecoder.delegate = self
        // Turn on the drone's "Command Mode" with a delay because we just turned on the sockets
        DispatchQueue.global().async {
            sleep(2)
            self.sendCommand(CMD.on)
        }
    }
    
    // MARK: - Tello Command Methods
    
    func takeOff() {
        self.sendCommand(CMD.takeOff)
    }
    /// Can sometimes be ignored, especially if within first 5 seconds or so of flight time
    func land() {
        self.sendCommand(CMD.land)
    }
    /// EMERGENCY STOP, drone motors will cease immediately
    func stop() {
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
                self.moveTimer.invalidate()
            }
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
        isCameraOn.toggle()
        // command tello to stream video
        let videoStreamCommand = isCameraOn ? CMD.streamOn : CMD.streamOff
        self.sendCommand(videoStreamCommand)
        guard self.isCameraOn else { return }
        displayVideoStream()
    }
    /// Listens to the video stream broadcast from the drone
    private func displayVideoStream() {
        /// Video data is stored and processed in this variable as it is received
        var videoFrameBuffer: [Byte] = []
        DispatchQueue.global(qos: .userInteractive).async {
            // When user toggles camera this will cease
            while self.isCameraOn {
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
                let (data, _, _) = self.commandResponseServer.recv(2048)
                if let responseData = data,
                    let response = String(bytes: responseData, encoding: .utf8) {
                    print("Command Response: \(response)")
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
        }
    }
}
