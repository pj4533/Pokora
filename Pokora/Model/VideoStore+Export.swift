//
//  VideoStore+Export.swift
//  Pokora
//
//  Created by PJ Gray on 5/3/23.
//

import Foundation
import AVKit

extension VideoStore {
    func exportVideoWithPNGs(videoURL: URL, pngURLs: [URL], outputURL: URL) async throws -> URL {
        await MainActor.run {
            isExporting = true
        }
        do {
            guard pngURLs.count > 0 else {
                throw NSError(domain: "Empty PNG URLs array", code: -1, userInfo: nil)
            }

            let asset = AVAsset(url: videoURL)
            let videoTrack = try await asset.loadTracks(withMediaType: .video).first!
            let audioTrack = try await asset.loadTracks(withMediaType: .audio).first!
            
            let composition = AVMutableComposition()
            let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            try await audioCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.load(.duration)), of: audioTrack, at: .zero)
            
            let videoSize = try await videoTrack.load(.naturalSize)
            let videoFPS = try await videoTrack.load(.nominalFrameRate)
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: videoSize.width,
                AVVideoHeightKey: videoSize.height
            ]
            
            let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoWriterInput.expectsMediaDataInRealTime = false
            
            let pixelBufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB])

            let audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
            audioWriterInput.expectsMediaDataInRealTime = false

            let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
            assetWriter.add(videoWriterInput)
            assetWriter.add(audioWriterInput)
            
            // Set up an AVAssetReader for the composition and an AVAssetReaderTrackOutput for the audio track
            let assetReader = try AVAssetReader(asset: composition)
            let audioReaderOutput = AVAssetReaderTrackOutput(track: audioCompositionTrack!, outputSettings: nil)
            assetReader.add(audioReaderOutput)

            assetReader.startReading() // Start reading samples from the composition's audio track

            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: .zero)
            
            let frameDuration = CMTime(value: 1, timescale: CMTimeScale(videoFPS))
            var currentFrameTime = CMTime.zero
            
            for (index, pngURL) in pngURLs.enumerated() {
                // This was hard to figure out...interleaving this audio/video stuff, wow. 😵‍💫
                while !videoWriterInput.isReadyForMoreMediaData {
                    if audioWriterInput.isReadyForMoreMediaData {
                        if let audioSampleBuffer = audioReaderOutput.copyNextSampleBuffer() {
                            audioWriterInput.append(audioSampleBuffer)
                        } else {
                            audioWriterInput.markAsFinished()
                        }
                    }
                }

                guard let image = NSImage(contentsOf: pngURL) else {
                    throw NSError(domain: "Image not found", code: -1, userInfo: nil)
                }
                
                let pixelBuffer = try createPixelBuffer(from: image, with: videoSize)
                let success = pixelBufferAdapter.append(pixelBuffer, withPresentationTime: currentFrameTime)
                
                if !success {
                    throw NSError(domain: "Failed to append pixel buffer", code: -1, userInfo: nil)
                }
                                
                currentFrameTime = CMTimeAdd(currentFrameTime, frameDuration)
                
                if index == pngURLs.count - 1 {
                    videoWriterInput.markAsFinished()
                }
            }

            // After video finished, check for remaining audio -- short clips?
            while audioWriterInput.isReadyForMoreMediaData {
                if let audioSampleBuffer = audioReaderOutput.copyNextSampleBuffer() {
                    audioWriterInput.append(audioSampleBuffer)
                } else {
                    audioWriterInput.markAsFinished()
                }
            }

            await assetWriter.finishWriting()
        } catch let error {
            throw error
        }
        
        await MainActor.run {
            isExporting = false
        }

        return outputURL
    }

    func createPixelBuffer(from image: NSImage, with size: CGSize) throws -> CVPixelBuffer {
        let attrs: [CFString: Any?] = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferWidthKey: Int(size.width),
            kCVPixelBufferHeightKey: Int(size.height),
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32ARGB
        ]
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, attrs as NSDictionary, &pixelBuffer)
        
        guard let buffer = pixelBuffer, status == kCVReturnSuccess else {
            throw NSError(domain: "Failed to create pixel buffer", code: Int(status), userInfo: nil)
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        guard let context = CGContext(
            data: pixelData,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            throw NSError(domain: "Failed to create CGContext", code: -1, userInfo: nil)
        }
        
        context.clear(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let imageRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            context.draw(cgImage, in: imageRect)
        } else {
            throw NSError(domain: "Failed to create CGImage from NSImage", code: -1, userInfo: nil)
        }
        
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
    }
}
