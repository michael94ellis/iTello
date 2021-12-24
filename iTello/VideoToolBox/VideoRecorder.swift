
//
//  VideoRecorder.swift
//  iTello
//
//  Created by Michael Ellis on 12/21/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import Foundation

import UIKit
import AVFoundation
import Photos
import AssetsLibrary

class VideoRecorder: NSObject {
    
    var isRecording: Bool = false
    var frameDuration: CMTime = CMTimeMake(value: 0, timescale: 0)
    var frameCounter = 0
    var assetWriter: AVAssetWriter?
    var assetWriterInput: AVAssetWriterInput?
    var videoAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var path = ""
    private var outputURL: URL?
    
    private func handlePhotoLibraryAuth() {
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization { authStatus in
                if authStatus != .authorized {
                    print(authStatus)
                    // TODO: Handle this error
                }
            }
        }
    }
    
    private func createFilePath() {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory: NSURL = urls.first as NSURL? else {
            fatalError("documentDir Error")
        }
        guard let videoOutputURL = documentDirectory.appendingPathComponent("iTello-\(Date()).mp4") else {
            print("Error: Cannot create Video Output file path URL")
            return
        }
        self.outputURL = videoOutputURL
        self.path = videoOutputURL.path
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                print("Unable to delete file: \(error) : \(#function).")
                return
            }
        }
    }
    
    private func saveRecordingToPhotoLibrary() {
        guard FileManager.default.fileExists(atPath: self.path) else {
            print("Error: The file: \(self.path) doesn't exist, cannot move file to camera roll")
            return
        }
        print("The file: \(self.path) has been save into documents folder, and is ready to be moved to camera roll")
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: self.path))
        }) { completed, error in
            guard completed else {
                print ("Error: Cannot move the video \(self.path) to camera roll, error: \(String(describing: error?.localizedDescription))")
                return
            }
            print("Video \(self.path) has been moved to camera roll")
        }
    }
    
    func startRecording(using formatDescription: CMFormatDescription) {
        guard !self.isRecording else {
            print("Warning: Cannot start recording because \(Self.self) is already recording")
            return
        }
        // 30 fps - 30 pictures will equal 1 second of video
        self.frameDuration = CMTime(seconds: 1.0/30.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        self.handlePhotoLibraryAuth()
        self.createFilePath()
        
        // set up the AVAssetWriter using the format description from the first sample buffer captured
        guard self.setupAssetWriter(format: formatDescription) else {
            print("Error: Failed to set up asset writer")
            return
        }
        
        self.isRecording = true
    }
    
    func appendFrame(_ sampleBuffer: CVPixelBuffer) {
        let currentPresentationTime = CMTime(value: CMTimeValue(frameCounter), timescale: 30)
        frameCounter += 1
        
        // append the sample buffer if we can and increment presentation time
        guard let writeInput = self.assetWriterInput, writeInput.isReadyForMoreMediaData else {
            print("Error: AVAssetWriterInput not ready for more media")
            return
        }
        
        if let videoAdaptor = videoAdaptor,
            videoAdaptor.append(sampleBuffer, withPresentationTime: currentPresentationTime) {
            print("Added frame")
        } else {
            let error = self.assetWriter!.error
            NSLog("Error: Failed to append sample buffer: \(error!)")
        }
        // release the copy of the sample buffer we made
    }
    
    private func setupAssetWriter(format formatDescription: CMFormatDescription?) -> Bool {
        // allocate the writer object with our output file URL
        guard let videoWriter = try? AVAssetWriter(outputURL: URL(fileURLWithPath: self.path), fileType: AVFileType.mp4),
              formatDescription != nil else {
                  print("Error: No Format For Video to create AVAssetWriter")
                  return false
              }
        self.assetWriter = videoWriter
        // initialize a new input for video to receive sample buffers for writing
        // passing nil for outputSettings instructs the input to pass through appended samples, doing no processing before they are written
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: nil, sourceFormatHint: formatDescription)
        videoInput.expectsMediaDataInRealTime = true
        
        let pixelBufferAttributes = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey: "1280",
            kCVPixelBufferHeightKey: "720"] as [String: Any]
        self.videoAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: pixelBufferAttributes)
        
        guard videoWriter.canAdd(videoInput) else {
            print("Error: Cannot add Video Input to AVAssetWriter")
            return false
        }
        videoWriter.add(videoInput)
        
        // initiates a sample-writing at time 0
        self.nextPTS = CMTime.zero
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: CMTime.zero)
        self.assetWriter = videoWriter
        self.assetWriterInput = videoInput
        return true
    }

    func stopRecording(completion: @escaping (Bool) -> ()) {
        guard self.isRecording else {
            print("Warning: Cannot stop recording because \(Self.self) is not recording")
            completion(false)
            return
        }
        guard assetWriter != nil else {
            print("Error: AssetWriter is nil")
            completion(false)
            return
        }
        assetWriterInput!.markAsFinished()
        assetWriter?.finishWriting() {
            self.assetWriterInput = nil
            self.saveRecordingToPhotoLibrary()
            self.assetWriter = nil
            self.isRecording = false
            completion(true)
        }
    }
}