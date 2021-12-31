
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
import AssetsLibrary

final class VideoRecorder: NSObject {
    
    var isRecording: Bool = false
    var frameDuration: CMTime = CMTimeMake(value: 0, timescale: 0)
    var nextPTS: CMTime = CMTimeMake(value: 0, timescale: 0)
    var assetWriter: AVAssetWriter?
    var assetWriterInput: AVAssetWriterInput?
    private let store = TelloStoreViewModel()
    private var path = ""
    private var outputURL: URL?
    
    private func createFilePath() {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory: NSURL = urls.first as NSURL? else {
            print("Error: documentDir Error")
            return
        }
        let date = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        guard let videoOutputURL = documentDirectory.appendingPathComponent("iTello_\(month)-\(day)_\(hour)-\(minute)-\(second).mp4") else {
            print("Error: Cannot create Video Output file path URL")
            return
        }
        self.outputURL = videoOutputURL
        self.path = videoOutputURL.path
        print(self.path)
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                print("Unable to delete file: \(error) : \(#function).")
                return
            }
        }
    }
    
    public func startStop() {
        if self.isRecording {
            self.stopRecording() { successfulCompletion in
                print("Stopped Recording: \(successfulCompletion)")
            }
        } else {
            self.startRecording()
        }
    }
    
    private func startRecording() {
        guard !self.isRecording else {
            print("Warning: Cannot start recording because \(Self.self) is already recording")
            return
        }
        guard self.store.hasPurchasedPro else {
            WifiManager.shared.isConnected = false
            return
        }
        self.createFilePath()
        print("Started Recording")
        self.isRecording = true
    }
    
    public func appendFrame(_ sampleBuffer: CMSampleBuffer) {
        // set up the AVAssetWriter using the format description from the first sample buffer captured
        if self.assetWriter == nil {
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
            guard self.setupAssetWriter(format: formatDescription) else {
                print("Error: Failed to set up asset writer")
                self.assetWriter = nil
                return
            }
        }
        guard self.assetWriter != nil else {
            print("Error: Attempting to append frame when AVAssetWriter is nil")
            return
        }
        // re-time the sample buffer - in this sample frameDuration is set to 30 fps
        var timingInfo = CMSampleTimingInfo.invalid // a way to get an instance without providing 3 CMTime objects
        timingInfo.duration = self.frameDuration
        timingInfo.presentationTimeStamp = self.nextPTS
        var sbufWithNewTiming: CMSampleBuffer? = nil
        guard CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault,
                                                    sampleBuffer: sampleBuffer,
                                                    sampleTimingEntryCount: 1, // numSampleTimingEntries
                                                    sampleTimingArray: &timingInfo,
                                                    sampleBufferOut: &sbufWithNewTiming) == 0 else {
            print("Error: Failed to set up CMSampleBufferCreateCopyWithNewTiming")
            return
        }
        
        // append the sample buffer if we can and increment presentation time
        guard let writeInput = self.assetWriterInput, writeInput.isReadyForMoreMediaData else {
            print("Error: AVAssetWriterInput not ready for more media")
            return
        }
        guard let sbufWithNewTiming = sbufWithNewTiming else {
            print("Error: sbufWithNewTiming is nil")
            return
        }
        
        if writeInput.append(sbufWithNewTiming) {
            self.nextPTS = CMTimeAdd(self.frameDuration, self.nextPTS)
        } else if let error = self.assetWriter?.error {
            logError(error)
            print("Error: Failed to append sample buffer: \(error)")
        } else {
            print("Error: Something went horribly wrong with appending sample buffer")
        }
        // release the copy of the sample buffer we made
    }
    
    private func setupAssetWriter(format formatDescription: CMFormatDescription?) -> Bool {
        // allocate the writer object with our output file URL
        let videoWriter: AVAssetWriter
        do {
            videoWriter = try AVAssetWriter(outputURL: URL(fileURLWithPath: self.path), fileType: AVFileType.mp4)
        } catch {
            logError(error)
            return false
        }
        guard formatDescription != nil else {
            print("Error: No Format For Video to create AVAssetWriter")
            return false
        }
        // initialize a new input for video to receive sample buffers for writing
        // passing nil for outputSettings instructs the input to pass through appended samples, doing no processing before they are written
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: nil, sourceFormatHint: formatDescription)
        videoInput.expectsMediaDataInRealTime = true
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

    private func stopRecording(completion: @escaping (Bool) -> ()) {
        guard self.isRecording else {
            print("Warning: Cannot stop recording because \(Self.self) is not recording")
            completion(false)
            return
        }
        self.isRecording = false
        guard assetWriter != nil else {
            print("Error: AssetWriter is nil")
            completion(false)
            return
        }
        assetWriterInput!.markAsFinished()
        assetWriter?.finishWriting() {
            self.assetWriter = nil
            self.assetWriterInput = nil
            self.path = ""
            self.outputURL = nil
            completion(true)
        }
    }
}
