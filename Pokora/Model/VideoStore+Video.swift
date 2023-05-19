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
    
    func extractFrames() async {
        await MainActor.run {
            isExtracting = true
        }
        do {
            let cachesDirectory = try project.getProjectCacheDirectory()
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
                        
                        while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
                            // see below. Duuurrrrr, what is this.
                            let ughIndex = index
                            await MainActor.run {
                                self.timingStatus = "[ \(ughIndex) of \(project.video.lastFrameIndex ?? 0) ]"
                            }

                            let path = cachesDirectory.appendingPathComponent("out\(String(format: "%05d", index)).png")

                            if FileManager().fileExists(atPath: path.path) {
                                if let imageSize = NSImage(contentsOf: path)?.size, imageSize.width == 512 {
                                    print("Skipped extracting: \(path.lastPathComponent) INDEX: \(index)")
                                    frames.append(Frame(index: index, url: path))
                                    index += 1
                                    continue
                                }
                            }
                            
                            print("Extracting: \(path.absoluteString)")

                            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                                let ciimage = CIImage(cvImageBuffer: imageBuffer)
                                let scaleFactor = min(512.0 / ciimage.extent.width, 512.0 / ciimage.extent.height)
                                let resizedCIImage = ciimage.transformed(by: CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
                                
                                // Create a new CIImage with the desired size and a black background.
                                let blackBackground = CIImage(color: CIColor(red: 0, green: 0, blue: 0)).cropped(to: CGRect(x: 0, y: 0, width: 512, height: 512))
                                
                                // Calculate the position at which to place the resized image (centered within the new image).
                                let targetX = (512 - resizedCIImage.extent.width) / 2
                                let targetY = (512 - resizedCIImage.extent.height) / 2
                                
                                // Composite the resized image on top of the black background.
                                let finalImage = resizedCIImage.transformed(by: CGAffineTransform(translationX: targetX, y: targetY)).composited(over: blackBackground)

                                if let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) {
                                    let format = CIFormat.RGBA8
                                    let context = CIContext()
                                    try context.writePNGRepresentation(of: finalImage, to: path, format: format, colorSpace: colorSpace)
                                }
                            }

//                            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
//                                let ciimage = CIImage(cvImageBuffer: imageBuffer)
//                                let scaleFactor = 512.0 / ciimage.extent.width
//                                let resizedCIImage = ciimage.transformed(by: CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
//
//                                if let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) {
//                                    let format = CIFormat.RGBA8
//                                    let context = CIContext()
//                                    try context.writePNGRepresentation(of: resizedCIImage, to: path, format: format, colorSpace: colorSpace)
//                                }
//                            }
                            frames.append(Frame(index: index, url: path))
                            print("APPENDED \(index)")
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
            await MainActor.run {
                isExtracting = false
            }
        }
    }
}
