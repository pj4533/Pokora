//
//  VideoStore+Video.swift
//  Pokora
//
//  Created by PJ Gray on 5/3/23.
//

import Foundation
import AVFoundation
import AVKit

extension VideoStore {
    func loadVideo() async throws {
        if let bookmarkData = project.video.bookmarkData {
            var isStale = false
            let bookmarkedURL = try URL(resolvingBookmarkData: bookmarkData,
                                        options: .withSecurityScope,
                                        relativeTo: nil,
                                        bookmarkDataIsStale: &isStale)
            
            if isStale {
                // The bookmarked data is stale, handle this error appropriately in your app
            } else {
                if bookmarkedURL.startAccessingSecurityScopedResource() {
                    // You have access to the file, you can perform your file operations here

                    try await loadVideo(url: bookmarkedURL)

                    // Make sure to stop accessing the resource when you're done
                    bookmarkedURL.stopAccessingSecurityScopedResource()
                }
            }
        }
    }
    
    func loadVideo(url: URL) async throws {
        let bookmarkData = try url.bookmarkData(options: .withSecurityScope,
                                                includingResourceValuesForKeys: nil,
                                                relativeTo: nil)
        let localVideo = Video(bookmarkData: bookmarkData)
        let player = AVPlayer(url: url)
        let framerate = try await player.currentItem?.asset.loadTracks(withMediaType: .video).first?.load(.nominalFrameRate)
        if let durationTime = try await player.currentItem?.asset.load(.duration) {
            let duration = CMTimeGetSeconds(durationTime)

            await MainActor.run {
                self.player = player
                project.video = localVideo
                project.video.framerate = framerate
                project.video.duration = duration
            }
            
            addTimeObserver()
        }
    }

    func processFrames(modelURL: URL?) async {
        await MainActor.run {
            self.shouldProcess = true
            self.isProcessing = true
        }
        for (index, frame) in (project.video.frames ?? []).enumerated() {
            do {
                try await self.process(frame: frame, atIndex: index, modelURL: modelURL)
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    // TODO: throw error here and use error dialog code
//                        self.showErrorDialog(with: error)
                }
            }
            if !self.shouldProcess { break }
        }
        await MainActor.run {
            self.isProcessing = false
        }
    }
    
    func extractFrames() async {
        await MainActor.run {
            isExtracting = true
        }
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        do {
            if let bookmarkData = project.video.bookmarkData {
                var isStale = false
                let bookmarkedURL = try URL(resolvingBookmarkData: bookmarkData,
                                            options: .withSecurityScope,
                                            relativeTo: nil,
                                            bookmarkDataIsStale: &isStale)
                
                if isStale {
                    // The bookmarked data is stale, handle this error appropriately in your app
                } else {
                    if bookmarkedURL.startAccessingSecurityScopedResource() {
                        // You have access to the file, you can perform your file operations here

                        let asset = AVAsset(url: bookmarkedURL)
                        let reader = try AVAssetReader(asset: asset)
                        
                        let tracks = try await asset.loadTracks(withMediaType: .video)
                        let videoTrack = tracks[0]
                        // read video frames as BGRA
                        let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
                        
                        reader.add(trackReaderOutput)
                        reader.startReading()
                        
                        var frames: [Frame] = []
                        var index = 0
                        
                        // this is how you get the number of frames, but the non async version is deprecated.
                        //                        print("TRACK: \(Int(videoTrack.timeRange.duration.seconds * Double(videoTrack.nominalFrameRate)))")
                        while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
                            // see below. Duuurrrrr, what is this.
                            let ughIndex = index
                            await MainActor.run {
                                self.timingStatus = "[ \(ughIndex) of \(project.video.lastFrameIndex ?? 0) ]"
                            }

                            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                                let ciimage = CIImage(cvImageBuffer: imageBuffer)
                                let scaleFactor = 512.0 / ciimage.extent.width
                                let resizedCIImage = ciimage.transformed(by: CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
                                
                                let path = cachesDirectory.appendingPathComponent("out\(String(format: "%05d", index)).png")
                                print("\(path.absoluteString)")
                                if !FileManager().fileExists(atPath: path.path) {
                                    if let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) {
                                        let format = CIFormat.RGBA8
                                        let context = CIContext()
                                        try context.writePNGRepresentation(of: resizedCIImage, to: path, format: format, colorSpace: colorSpace)
                                    }
                                }
                                frames.append(Frame(index: index, url: path))
                            }
                            index += 1
                        }
                        
                        // wat - i dont get this
                        let letFrames = frames
                        await MainActor.run {
                            project.video.frames = letFrames
                            isExtracting = false
                        }

                        // Make sure to stop accessing the resource when you're done
                        bookmarkedURL.stopAccessingSecurityScopedResource()
                    }
                }
            }
        } catch let error {
            print(error.localizedDescription)
            isExtracting = false
        }
    }
}
