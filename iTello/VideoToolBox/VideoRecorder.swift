//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import AVFoundation
import Foundation
import UIKit

/// A class to handle video recording
final class VideoRecorder: NSObject {

    /// start time of the current clip
    private(set) var startTime: CMTime = CMTime.zero
    var currentVideoSampleBuffer: CMSampleBuffer?
    private var currentAudioSampleBuffer: CMSampleBuffer?
    private var currentPresentationTime: CMTime?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var videoQueue: DispatchQueue = DispatchQueue(label: "VideoRecordingQueue")

    // MARK: - external methods
    /// Starts video recording
    ///
    /// - Parameters:
    ///   - assetWriter: the asset writer to append buffers
    ///   - pixelBufferAdaptor: the pixel buffer adapator
    ///   - audioInput: the audio input for the asset writer. This can be nil
    func startRecordingVideo(assetWriter: AVAssetWriter, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor) {
        self.assetWriter = assetWriter
        self.videoInput = pixelBufferAdaptor.assetWriterInput
        guard assetWriter.startWriting() else {
            assertionFailure("asset writer couldn't start")
            return
        }
        self.assetWriter?.startSession(atSourceTime: self.startTime)
    }

    /// Stops recording video and exports as a mp4
    ///
    /// - Parameter completion: success boolean if asset writer completed
    func stopRecordingVideo(completion: @escaping (Bool) -> Void) {
        if let sampleBuffer = currentVideoSampleBuffer {
            startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        }
        videoInput?.markAsFinished()
        assetWriter?.finishWriting(completionHandler: { [weak self] in
            completion(self?.assetWriter?.status == .completed && self?.assetWriter?.error == nil)
        })
    }

    // MARK: - sample buffer processing
    
    /// The video sample buffer processor
    ///
    /// - Parameter sampleBuffer: The input video sample buffer
    func processVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        self.currentVideoSampleBuffer = sampleBuffer
        var newBuffer: CMSampleBuffer? = nil
        CMSampleBufferCreateCopy(allocator: kCFAllocatorDefault, sampleBuffer: sampleBuffer, sampleBufferOut: &newBuffer)
        guard let buffer = newBuffer else {
            print("Warning: nil buffer")
            return
        }
        print(self.currentClipDuration() ?? "Error: No Clip Duration")
        self.videoQueue.async {
            if self.videoInput?.isReadyForMoreMediaData == true {
                print("append sample buffer \(String(describing: self.videoInput?.append(buffer)))")
            }
        }
    }
    
    /// Gets the current clip duration, if recording. otherwise it is nil
    ///
    /// - Returns: time interval in seconds of the current clip
    func currentClipDuration() -> TimeInterval? {
        guard let currentVideoSample = currentVideoSampleBuffer else { return nil }
        let timestamp = CMSampleBufferGetPresentationTimeStamp(currentVideoSample)
        let difference = CMTimeSubtract(timestamp, startTime)
        return CMTimeGetSeconds(difference)
    }

    func assetWriterURL() -> URL? {
        return assetWriter?.outputURL
    }
}
