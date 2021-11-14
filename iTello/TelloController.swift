//
//  TelloController.swift
//  iTello
//
//  Swift Class to interact with the DJI/Ryze Tello drone using the official Tello api.
//  Tello API documentation:
//  https://dl-cdn.ryzerobotics.com/downloads/tello/20180910/Tello%20SDK%20Documentation%20EN_1.3.pdf
//

import VideoToolbox
import UIKit


/// This Swift object can control a DJI Tello drone and also decode and display it's video stream
class TelloController: NSObject, VideoFrameDecoderDelegate {
    /// Indicates whether or not the drone has been put into command mode
    private(set) var commandable = false
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
    // TODO: Timer to send a message(CMD.on) after every 4 second the user hasn't sent a command to keep the drone active
    
    // MARK: - Stream Data Vars
    
    private var responseWaiter = Timer()
    /// Last known battery amount received from tello
    var battery = ""
    /// Last known Signal to Noise ratio for WiFi received from tello
    var wifi = ""
    private lazy var videoDecoder = VideoFrameDecoder()
    /// A reference to the image view where the video will be displayed
    var videoView: UIImageView?
    
    // UDP Connections
    // TODO: Video
//    var videoClient = UDPClient(address: Tello.ResponseIPAddress, port: Tello.VideoStreamPort)
    var stateClient = UDPClient(address: Tello.ResponseIPAddress, port: Tello.StatePort)
    var commandClient = UDPClient(address: Tello.IPAddress, port: Tello.CommandPort)
    
    /// The TelloController will spawn 2 threads immediately, on each thread will be on of the two UDP objects above
    ///     A receiving/listener for both Drone State and Command Responses
    /// If the video stream is enabled a third thread will listen/receive the video stream
    override init() {
        super.init()
        VideoFrameDecoder.delegate = self
        
        commandClient?.messageReceived = handleCommandResponse(message:)
        stateClient?.messageReceived = handleStateStream(data:)
//        videoClient?.messageReceived = handleVideoStream(data:)
        commandClient?.setupConnection()
//        videoClient?.setupListener()
        
        repeatCommandForResponse(for: CMD.on)
    }
    
    /// This var will decrease as the initial command is sent multiple times
    private var commandRepeatMax = 4
    /// Repeats a comment until an `ok` is received from the Tello
    private func repeatCommandForResponse(for command: String) {
        responseWaiter = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            if !self.commandable, self.commandRepeatMax > 0 {
                self.sendCommand(command)
                self.commandRepeatMax -= 1
            } else {
                self.responseWaiter.invalidate()
                self.commandRepeatMax = 4
                // Now that the Tello is in command mode we can listen for State
                self.stateClient?.setupListener()
//                if TelloSettings.isCameraOn {
//                    self.handleVideoDisplay()
//                }
            }
        }
    }

    // MARK: - Tello Command Methods
    
    func takeOff() {
        sendCommand(CMD.takeOff)
    }
    /// Can sometimes be ignored, especially if within first 5 seconds or so of flight time
    func land() {
        repeatCommandForResponse(for: CMD.land)
    }
    /// EMERGENCY STOP, drone motors will cease immediately, should not always be viasible to user
    func emergencyLand() {
        sendCommand(CMD.off)
    }
    /// See the FLIP enum for list of available flip directions
    func flip(_ direction: FLIP) {
        sendCommand(direction.commandValue)
    }
    
    func beginOrEndRecording() {
        videoDecoder.isRecording.toggle()
    }
    
    /// Called by the UI to toggle the camera state
    func handleVideoDisplay() {
        // command tello to stream video
        let videoStreamCommand = TelloSettings.isCameraOn ? CMD.streamOn : CMD.streamOff
        sendCommand(videoStreamCommand)
        guard TelloSettings.isCameraOn else {
            return
        }
        //        videoClient?.delegate = self
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
        }
    }
    
    private func sendCommand(_ command: String) {
        guard let data = command.data(using: .utf8),
            let udpClient =  commandClient else {
                print("Error: cannot send command")
                return
        }
        print("Sending Command: \(command)")
        udpClient.sendAndReceive(data)
        
    }
    
    // MARK: - Handle Stream Data
    
    /// Read data from the ongoing STATE stream
    private func handleCommandResponse(message: Data) {
        guard let message = String(data: message, encoding: .utf8), message == "ok" else {
            print("Error with command client response")
            return
        }
        print("Command: ok")
        commandable = true
    }
    /// Read data from the ongoing STATE stream
    private func handleStateStream(data: Data) {
        guard let message = String(data: data, encoding: .utf8) else {
                print("Error with command client response")
                return
        }
        let stateValues = message.split(separator: ";")
        let batteryLevel = stateValues.first(where: { $0.hasPrefix("bat") })
        battery = batteryLevel?.split(separator: ":").last?.description ?? ""
    }
    /// Listens to the video stream broadcast from the drone
    func handleVideoStream(data: Data) {
        /// Video data is stored and processed in this variable as it is received
        var videoFrameBuffer: FrameData = []
        // When user toggles camera this will cease
        while TelloSettings.isCameraOn {
            // No frame is a full image, they must be received separately and assembled
            decodeVideoData(frameBuffer: &videoFrameBuffer, data: [UInt8](data))
        }
    }
    /// Passes the received frame data to the video decoder
    private func decodeVideoData(frameBuffer: inout FrameData, data: FrameData?) {
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
            // Record CMSampleBuffer with AVFoundation
            if self.videoDecoder.isRecording,
                let videoPixelBuffer = self.videoDecoder.videoWriterInputPixelBufferAdaptor,
                videoPixelBuffer.assetWriterInput.isReadyForMoreMediaData {
                print(videoPixelBuffer.append(frame, withPresentationTime: CMTimeMake(value: self.videoDecoder.videoFrameCounter, timescale: self.videoDecoder.videoFPS)))
                self.videoDecoder.videoFrameCounter += 1
            }
        }
    }
    
    // MARK: - Add image to Library
    
    public func takePhoto() {
        guard let image = self.videoView?.image else {
            print("Error: Can't take photo, no video frame is displayed")
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            print(error)
        } else {
            print("Your image has been saved to your photos.")
        }
    }
    
    // MARK: - Facial Recognition
    
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
