////
////  StopnGo.swift
////  iTello
////
////  Created by Michael Ellis on 12/22/21.
////  Copyright © 2021 Mellis. All rights reserved.
//////
////  VideoRecorder.swift
////  iTello
////
////  Created by Michael Ellis on 12/21/21.
////  Copyright © 2021 Mellis. All rights reserved.
////
//
//import Foundation
//
//import UIKit
//import AVFoundation
//import AssetsLibrary
//
//class VideoRecorde222r: NSObject {
//
//    var isRecording: Bool = false
//    var frameDuration: CMTime = CMTimeMake(value: 0, timescale: 0)
//    var nextPTS: CMTime = CMTimeMake(value: 0, timescale: 0)
//    var assetWriter: AVAssetWriter?
//    var assetWriterInput: AVAssetWriterInput?
//    var outputURL: URL?
//    
//    @discardableResult
//    private func setupAVCapture() -> Bool {
//        // 30 fps - 30 pictures will equal 1 second of video
//        frameDuration = CMTimeMakeWithSeconds(1.0/30.0, preferredTimescale: 90000)
//    }
//
//    private func setupAssetWriterForURL(_ fileURL: URL, formatDescription: CMFormatDescription) -> Bool {
//        // allocate the writer object with our output file URL
//        do {
//            assetWriter = try AVAssetWriter(outputURL: fileURL, fileType: .mov)
//        } catch _ {
//            assetWriter = nil
//            return false
//        }
//        
//        // initialized a new input for video to receive sample buffers for writing
//        // passing nil for outputSettings instructs the input to pass through appended samples, doing no processing before they are written
//        assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: nil)
//        assetWriterInput!.expectsMediaDataInRealTime = true
//        if assetWriter!.canAdd(assetWriterInput!) {
//            assetWriter!.add(assetWriterInput!)
//        }
//        
//        // specify the prefered transform for the output file
//        var rotationDegrees: CGFloat
//        switch UIDevice.current.orientation {
//        case .portraitUpsideDown:
//            rotationDegrees = -90.0
//        case .landscapeLeft: // no rotation
//            rotationDegrees = 0.0
//        case .landscapeRight:
//            rotationDegrees = 180.0
//        case .portrait:
//            fallthrough
//        case .unknown:
//            fallthrough
//        case .faceUp:
//            fallthrough
//        case .faceDown:
//            fallthrough
//        default:
//            rotationDegrees = 90.0
//        }
//        let rotationRadians = DegreesToRadians(rotationDegrees)
//        assetWriterInput!.transform = CGAffineTransform(rotationAngle: rotationRadians)
//        
//        // initiates a sample-writing at time 0
//        nextPTS = CMTime.zero
//        assetWriter!.startWriting()
//        assetWriter!.startSession(atSourceTime: nextPTS)
//        
//        return true
//    }
//    
//    @IBAction func takePicture(_: AnyObject) {
//        // initiate a still image capture, return immediately
//        // the completionHandler is called when a sample buffer has been captured
//        let stillImageConnection = stillImageOutput?.connection(with: .video)
//        stillImageOutput?.captureStillImageAsynchronously(from: stillImageConnection!) {
//            imageDataSampleBuffer, error in
//            
//            // set up the AVAssetWriter using the format description from the first sample buffer captured
//            if self.assetWriter == nil {
//                self.outputURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())/\(mach_absolute_time()).mov")
//                //NSLog("Writing movie to \"%@\"", outputURL)
//                let formatDescription = CMSampleBufferGetFormatDescription(imageDataSampleBuffer!)
//                if !self.setupAssetWriterForURL(self.outputURL!, formatDescription: formatDescription!) {
//                    return
//                }
//            }
//            
//            // re-time the sample buffer - in this sample frameDuration is set to 5 fps
//            var timingInfo = CMSampleTimingInfo.invalid
//            timingInfo.duration = self.frameDuration
//            timingInfo.presentationTimeStamp = self.nextPTS
//            var sbufWithNewTiming: CMSampleBuffer? = nil
//            let err = CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault,
//                                                            sampleBuffer: imageDataSampleBuffer!,
//                                                            sampleTimingEntryCount: 1, // numSampleTimingEntries
//                                                            sampleTimingArray: &timingInfo,
//                                                            sampleBufferOut: &sbufWithNewTiming)
//            if err != 0 {
//                return
//            }
//            
//            // append the sample buffer if we can and increment presnetation time
//            if self.assetWriterInput?.isReadyForMoreMediaData ?? false {
//                if self.assetWriterInput!.append(sbufWithNewTiming!) {
//                    self.nextPTS = CMTimeAdd(self.frameDuration, self.nextPTS)
//                } else {
//                    let error = self.assetWriter!.error
//                    NSLog("failed to append sbuf: \(error!)")
//                }
//            }
//            
//            // release the copy of the sample buffer we made
//        }
//    }
//    
//    private func saveMovieToCameraRoll() {
//        // save the movie to the camera roll
//        let library = ALAssetsLibrary()
//        //NSLog("writing \"%@\" to photos album", outputURL!)
//        library.writeVideoAtPath(toSavedPhotosAlbum: outputURL) {
//            assetURL, error in
//            if error != nil {
//                NSLog("assets library failed (\(error!))")
//            } else {
//                do {
//                    try FileManager.default.removeItem(at: self.outputURL!)
//                } catch _ {
//                    NSLog("Couldn't remove temporary movie file \"\(self.outputURL!)\"")
//                }
//            }
//            self.outputURL = nil
//        }
//    }
//    
//    @IBAction func startStop(_ sender: UIBarButtonItem) {
//        if started {
//            if assetWriter != nil {
//                assetWriterInput!.markAsFinished()
//                assetWriter!.finishWriting {
//                    self.assetWriterInput = nil
//                    self.saveMovieToCameraRoll()
//                    self.assetWriter = nil
//                }
//            }
//            sender.title = "Start"
//            takePictureButton.isEnabled = false
//        } else {
//            sender.title = "Finish"
//            takePictureButton.isEnabled = true
//            
//        }
//        started = !started
//    }
//    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Release any cached data, images, etc that aren't in use.
//    }
//    
//    //MARK: - View lifecycle
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.setupAVCapture()
//        // Do any additional setup after loading the view, typically from a nib.
//    }
//    
//    override var shouldAutorotate : Bool {
//        return false
//    }
//    
//    
//
//
//import Foundation
