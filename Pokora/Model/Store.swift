//
//  Store.swift
//  Pokora
//
//  Created by PJ Gray on 2/24/23.
//

import Foundation
import AVKit

class Store {
    
    static func loadCachedFrames(url: URL, completionHandler: @escaping (Video?) -> Void) {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        print(cachesDirectory)
        var frames: [Frame] = []
        var index = 1
        // Define the regular expression pattern
        let regexPattern = "^out.*\\.png$"
        let regex = try! Regex(regexPattern)
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: cachesDirectory.path)
            // Filter the list of files to only include those that match the regex pattern
            let matchingFiles = try files.filter { filename in
                return try regex.firstMatch(in: filename) != nil
            }

            // Print the list of matching files
            for file in matchingFiles.sorted() {
                frames.append(Frame(index: index, inputUrl: cachesDirectory.appending(path: file)))
                index += 1
            }
            completionHandler(Video(url: url, frames: frames))
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // not sure if this should be static like this, i need to figure out more about how Stores work in the declarative world
    static func loadVideo(url: URL, completionHandler: @escaping (Video?) -> Void) {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        do {
            UserDefaults.standard.set(url, forKey: "currentVideoFile")
            
            let asset = AVAsset(url: url)
            let reader = try AVAssetReader(asset: asset)
            
            asset.loadTracks(withMediaType: .video) { tracks, error in
                do {
                    if let videoTrack = tracks?[0] {
                        // read video frames as BGRA
                        let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])

                        reader.add(trackReaderOutput)
                        reader.startReading()

                        var frames: [Frame] = []
                        var index = 1
                        
                        // this is how you get the number of frames, but the non async version is deprecated.
//                        print("TRACK: \(Int(videoTrack.timeRange.duration.seconds * Double(videoTrack.nominalFrameRate)))")
                        while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
                            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                                let ciimage = CIImage(cvImageBuffer: imageBuffer)
                                let scaleFactor = 512.0 / ciimage.extent.width
                                let resizedCIImage = ciimage.transformed(by: CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
                                
                                let path = cachesDirectory.appendingPathComponent("out\(String(format: "%05d", index)).png")
                                print("\(path.absoluteString)")
                                if let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) {
                                    let format = CIFormat.RGBA8
                                    let context = CIContext()
                                    try context.writePNGRepresentation(of: resizedCIImage, to: path, format: format, colorSpace: colorSpace)
                                }
                                frames.append(Frame(index: index, inputUrl: path))
                            }
                            index += 1
                        }
                        completionHandler(Video(url: url, frames: frames))
                    } else {
                        print("didn't get tracks")
                    }
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
