//
//  AVManager.swift
//  iTello
//
//  Created by Michael Ellis on 11/14/21.
//

import Foundation
import VideoToolbox
import Combine
import Photos
import UIKit.UIImage

class VideoStreamManager: NSObject, VideoFrameDecoderDelegate, ObservableObject {
    
    /// A reference to the image view where the video will be displayed
    private var videoListener: UDPListener?
    private var videoResponseListener: AnyCancellable?
    /// Video data is stored and processed in this variable as it is received
    private var videoFrameBuffer: FrameData = []
    @Published public var currentFrame: CGImage?
    
    /// If the video stream is enabled a third thread will listen/receive the video stream
    override init() {
        super.init()
        VideoFrameDecoder.delegate = self
    }
    
    deinit {
        self.currentFrame = nil
        self.videoListener?.cancel()
        self.videoResponseListener?.cancel()
    }
    
    func setup() {
        // Start listening for video stream frames
        self.videoListener = UDPListener(on: Tello.VideoStreamPort)
        self.videoResponseListener = self.videoListener?.$messageReceived.sink(receiveValue: { streamData in
            // No frame is a full image, they must be received separately and assembled
            self.handleVideoStream(data: streamData)
        })
    }
    
    /// Listens to the video stream broadcast from the drone and passes the received frame data to the video decoder
    func handleVideoStream(data: Data?) {
        guard let videoStreamData = data else {
            print("Warning: Video Stream Data Nil")
            return
        }
        // Combine previous buffer with current buffer
        self.videoFrameBuffer = self.videoFrameBuffer + videoStreamData
        // Check received NALU data for size validity
        if videoStreamData.count < 1460,
           self.videoFrameBuffer.count > 40 {
            // Update video frame
            VideoFrameDecoder.shared.interpretRawFrameData(&videoFrameBuffer)
            // Refresh the received data buffer to begin processing a new frame
            self.videoFrameBuffer = []
        }
    }
    
    /// This is called when the VideoFrameDecoder finishes decoding a frame
    func receivedDisplayableFrame(_ frame: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(frame, options: nil, imageOut: &cgImage)
        guard let displayableImage = cgImage else {
            print("Warning: Failed to decode a frame")
            return
        }
        self.currentFrame = displayableImage
    }
    
    
    public func takePhoto(cgImage: CGImage?) {
        guard let image = cgImage else {
            print("Error: Can't take photo, no video frame is displayed")
            return
        }
        let uiImage = UIImage(cgImage: image)
        UIImageWriteToSavedPhotosAlbum(uiImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            print(error)
        } else {
            print("Your image has been saved to your photos.")
        }
    }
}
