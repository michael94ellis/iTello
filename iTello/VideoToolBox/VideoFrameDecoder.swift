import Foundation
import VideoToolbox
import AVFoundation
import Photos

typealias FrameData = Array<UInt8>

protocol VideoFrameDecoderDelegate {
    func receivedDisplayableFrame(_ frame: CVPixelBuffer)
}

final class VideoFrameDecoder: ObservableObject {
    
    // I dislike this pattern but not as much as working in Obj-C
    static var delegate: VideoFrameDecoderDelegate?
    
    private var formatDesc: CMVideoFormatDescription?
    private var decompressionSession: VTDecompressionSession?
    private(set) public var videoRecorder: VideoRecorder = VideoRecorder()

    static let shared = VideoFrameDecoder()
    
    private init() { }
        
    public func interpretRawFrameData(_ frameData: inout FrameData) {
        var naluType = frameData[4] & 0x1F
        if naluType != 7 && formatDesc == nil { return }
        
        // Replace start code with the size
        var frameSize = CFSwapInt32HostToBig(UInt32(frameData.count - 4))
        memcpy(&frameData, &frameSize, 4)
        
        // The start indices for nested packets. Default to 0.
        var ppsStartIndex = 0
        var frameStartIndex = 0
        
        var sps: Array<UInt8>?
        var pps: Array<UInt8>?
        
        // SPS parameters
        if naluType == 7 {
            for i in 4..<40 {
                if frameData[i] == 0 && frameData[i+1] == 0 && frameData[i+2] == 0 && frameData[i+3] == 1 {
                    ppsStartIndex = i // Includes the start header
                    sps = Array(frameData[4..<i])
                    
                    // Set naluType to the nested packet's NALU type
                    naluType = frameData[i + 4] & 0x1F
                    break
                }
            }
        }
        // PPS parameters
        if naluType == 8 {
            for i in ppsStartIndex+4..<ppsStartIndex+34 {
                if frameData[i] == 0 && frameData[i+1] == 0 && frameData[i+2] == 0 && frameData[i+3] == 1 {
                    frameStartIndex = i
                    pps = Array(frameData[ppsStartIndex+4..<i])
                    
                    // Set naluType to the nested packet's NALU type
                    naluType = frameData[i+4] & 0x1F
                    break
                }
            }
            
            guard let sps = sps,
                  let pps = pps,
                  createFormatDescription(sps: sps, pps: pps) else {
                      print("===== ===== Failed to create formatDesc")
                      return
                  }
            guard createDecompressionSession() else {
                print("===== ===== Failed to create decompressionSession")
                return
            }
        }
        
        if (naluType == 1 || naluType == 5) && decompressionSession != nil {
            // If this is successful, the callback will be called
            // The callback will send the full decoded and decompressed frame to the delegate
            decodeFrameData(Array(frameData[frameStartIndex...frameData.count - 1]))
        }
    }
    
    private func decodeFrameData(_ frameData: FrameData) {
        let bufferPointer = UnsafeMutableRawPointer(mutating: frameData)
        // Replace the start code with the size of the NALU
        var frameSize = CFSwapInt32HostToBig(UInt32(frameData.count - 4))
        memcpy(bufferPointer, &frameSize, 4)
        // Create a memory location to store the processed image
        var outputBuffer: CVPixelBuffer?
        var blockBuffer: CMBlockBuffer?
        var status = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: bufferPointer,
            blockLength: frameData.count,
            blockAllocator: kCFAllocatorNull,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: frameData.count,
            flags: 0, blockBufferOut: &blockBuffer)
        // Return if there was an error allocating processed image location
        guard status == kCMBlockBufferNoErr else { return }
        // Do some image processing
        var sampleBuffer: CMSampleBuffer?
        let sampleSizeArray = [frameData.count]
        status = CMSampleBufferCreateReady(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            formatDescription: formatDesc,
            sampleCount: 1,
            sampleTimingEntryCount: 0,
            sampleTimingArray: nil,
            sampleSizeEntryCount: 1,
            sampleSizeArray: sampleSizeArray,
            sampleBufferOut: &sampleBuffer)
        
        // Return if there was an error
        if let buffer = sampleBuffer,
           status == kCMBlockBufferNoErr {
            let attachments: CFArray? = CMSampleBufferGetSampleAttachmentsArray(buffer, createIfNecessary: true)
            if let attachmentsArray = attachments {
                let dic = unsafeBitCast(CFArrayGetValueAtIndex(attachmentsArray, 0), to: CFMutableDictionary.self)
                CFDictionarySetValue(dic,
                                     Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                                     Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
                
                // Decompress with VideoToolbox
                var flagOut = VTDecodeInfoFlags(rawValue: 0)
                status = VTDecompressionSessionDecodeFrame(
                    decompressionSession!,
                    sampleBuffer: buffer,
                    flags: [],
                    frameRefcon: &outputBuffer,
                    infoFlagsOut: &flagOut)
                if self.videoRecorder.isRecording {
                    self.videoRecorder.appendFrame(buffer)
                }
            }
        }
    }
    
    private func createFormatDescription(sps: [UInt8], pps: [UInt8]) -> Bool {
        
        let pointerSPS = UnsafePointer<UInt8>(sps)
        let pointerPPS = UnsafePointer<UInt8>(pps)
        
        let dataParamArray = [pointerSPS, pointerPPS]
        let parameterSetPointers = UnsafePointer<UnsafePointer<UInt8>>(dataParamArray)
        
        let sizeParamArray = [sps.count, pps.count]
        let parameterSetSizes = UnsafePointer<Int>(sizeParamArray)
        
        let status = CMVideoFormatDescriptionCreateFromH264ParameterSets(
            allocator: kCFAllocatorDefault,
            parameterSetCount: 2,
            parameterSetPointers: parameterSetPointers,
            parameterSetSizes: parameterSetSizes,
            nalUnitHeaderLength: 4,
            formatDescriptionOut: &formatDesc)
        
        return status == noErr
    }
    
    private func createDecompressionSession() -> Bool {
        guard let desc = formatDesc else { return false }
        
        if let session = decompressionSession {
            VTDecompressionSessionInvalidate(session)
            decompressionSession = nil
        }
        
        let decoderParameters = NSMutableDictionary()
        let destinationPixelBufferAttributes = NSMutableDictionary()
        
        var outputCallback = VTDecompressionOutputCallbackRecord()
        outputCallback.decompressionOutputCallback = callback
        outputCallback.decompressionOutputRefCon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        let status = VTDecompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            formatDescription: desc,
            decoderSpecification: decoderParameters,
            imageBufferAttributes: destinationPixelBufferAttributes,
            outputCallback: &outputCallback,
            decompressionSessionOut: &decompressionSession)
        
        return status == noErr
    }
    
    private var callback: VTDecompressionOutputCallback = {(
        decompressionOutputRefCon: UnsafeMutableRawPointer?,
        sourceFrameRefCon: UnsafeMutableRawPointer?,
        status: OSStatus,
        infoFlags: VTDecodeInfoFlags,
        imageBuffer: CVPixelBuffer?,
        presentationTimeStamp: CMTime,
        duration: CMTime) in
        guard let newImage = imageBuffer,
              status == noErr else {
                  // -12909 is Bad Video Error, nothing too bad unless there's no feed
                  if status != -12909 {
                      print("===== Failed to decompress. VT Error \(status)")
                  }
                  return
              }
        // print("===== Image successfully decompressed")
        delegate?.receivedDisplayableFrame(newImage)
    }
}
