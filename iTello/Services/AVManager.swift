////
////  AVManager.swift
////  iTello
////
////  Created by Michael Ellis on 11/14/21.
////
//
//import Foundation
//import VideoToolbox
//import UIKit
//import Combine
//
//class AVManager: VideoFrameDecoderDelegate {
//    
//    var avDelegate: TelloAVDelegate?
//    private lazy var videoDecoder = VideoFrameDecoder()
//    /// A reference to the image view where the video will be displayed
//    var videoView: UIImageView?
//    var videoClient = UDPClient(address: Tello.ResponseIPAddress, port: Tello.VideoStreamPort)
//    var listener: AnyCancellable?
//    /// If the video stream is enabled a third thread will listen/receive the video stream
//    init() {
//        VideoFrameDecoder.delegate = self
////        self.listener = videoClient?.messageReceived.publisher.sink(receiveValue: { messageReceived in
////            self.handleVideoStream(data: messageReceived)
////        })
////        videoClient?.setupListener()
//    }
//    
//    func beginOrEndRecording() {
//        videoDecoder.isRecording.toggle()
//    }
//    
//    /// Called by the UI to toggle the camera state
//    func handleVideoDisplay() {
//        // command tello to stream video
//        let videoStreamCommand = TelloSettings.isCameraOn ? CMD.streamOn : CMD.streamOff
//        avDelegate?.sendCommand(videoStreamCommand)
//        guard TelloSettings.isCameraOn else {
//            return
//        }
//        //        videoClient?.delegate = self
//    }
//    /// Listens to the video stream broadcast from the drone
//    func handleVideoStream(data: Data) {
//        /// Video data is stored and processed in this variable as it is received
//        var videoFrameBuffer: FrameData = []
//        // When user toggles camera this will cease
//        while TelloSettings.isCameraOn {
//            // No frame is a full image, they must be received separately and assembled
//            decodeVideoData(frameBuffer: &videoFrameBuffer, data: [UInt8](data))
//        }
//    }
//    /// Passes the received frame data to the video decoder
//    private func decodeVideoData(frameBuffer: inout FrameData, data: FrameData?) {
//        if let videoStreamData = data {
//            // Combine previous buffer with current buffer
//            frameBuffer = frameBuffer + videoStreamData
//            // Check received NALU data for size validity
//            if videoStreamData.count < 1460,
//               frameBuffer.count > 40 {
//                // Update video frame
//                videoDecoder.interpretRawFrameData(&frameBuffer)
//                // Refresh the received data buffer to begin processing a new frame
//                frameBuffer = []
//            }
//        }
//    }
//    /// This is called when the VideoFrameDecoder finishes decoding a frame
//    func receivedDisplayableFrame(_ frame: CVPixelBuffer) {
//        var cgImage: CGImage?
//        VTCreateCGImageFromCVPixelBuffer(frame, options: nil, imageOut: &cgImage)
//        guard let displayableImage = cgImage else {
//            print("Failed to decode a frame")
//            return
//        }
//                DispatchQueue.main.async {
//        //            // Update video image with new frame
//                    self.videoView?.image = UIImage(cgImage: displayableImage)
//        //            //            let ciImage = CIImage(cgImage: displayableImage)
//        //            //            self.findFaces(in: ciImage)
//        //            // Record CMSampleBuffer with AVFoundation
//        //            if self.videoDecoder.isRecording,
//        //                let videoPixelBuffer = self.videoDecoder.videoWriterInputPixelBufferAdaptor,
//        //                videoPixelBuffer.assetWriterInput.isReadyForMoreMediaData {
//        //                print(videoPixelBuffer.append(frame, withPresentationTime: CMTimeMake(value: self.videoDecoder.videoFrameCounter, timescale: self.videoDecoder.videoFPS)))
//        //                self.videoDecoder.videoFrameCounter += 1
//        //            }
//                }
//    }
//    
//    // MARK: - Add image to Library
//    
//    public func takePhoto() {
//        guard let image = self.videoView?.image else {
//            print("Error: Can't take photo, no video frame is displayed")
//            return
//        }
//        // FIXME: - Take Photo for mac/iOS split
//        //        NSImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
//    }
//    
//    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
//        if let error = error {
//            // we got back an error!
//            print(error)
//        } else {
//            print("Your image has been saved to your photos.")
//        }
//    }
//    
//    // MARK: - Facial Recognition
//    
//    var faceBox: CGRect?
//    
//    func findFaces(in image: CIImage) {
//        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
//        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)!
//        
//        let faces = faceDetector.features(in: image)
//        
//        if let face = faces.first as? CIFaceFeature {
//            print("Found face at \(face.bounds)")
//            if !face.hasRightEyePosition {
//                print("i think i should go counter clockwise")
//            } else if !face.hasLeftEyePosition {
//                print("i think i should go clockwise")
//            }
//            if let lastFaceBox = faceBox {
//                if lastFaceBox.size.magnitude > face.bounds.size.magnitude + 50 {
//                    print("i think i should move back")
//                } else if lastFaceBox.size.magnitude < face.bounds.size.magnitude - 50 {
//                    print("i think i should move forward")
//                }
//            }
//            faceBox = face.bounds
//        }
//    }
//}
//
//extension CGSize: Comparable {
//    
//    public var magnitude: CGFloat { height * width }
//    
//    public static func < (lhs: CGSize, rhs: CGSize) -> Bool {
//        return lhs.magnitude < rhs.magnitude
//    }
//}
