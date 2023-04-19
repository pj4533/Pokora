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
        let inputRegexPattern = "^out(\\d+)\\.png$"
        let outputRegexPattern = "^out(\\d+)_processed\\.png$"

        let inputRegex = try! NSRegularExpression(pattern: inputRegexPattern)
        let outputRegex = try! NSRegularExpression(pattern: outputRegexPattern)
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: cachesDirectory.path)

            var inputFiles: [String: String] = [:]
            var outputFiles: [String: String] = [:]

            for file in files {
                if let match = inputRegex.firstMatch(in: file, range: NSRange(file.startIndex..., in: file)) {
                    let range = match.range(at: 1)
                    let fileNumber = (file as NSString).substring(with: range)
                    inputFiles[fileNumber] = file
                } else if let match = outputRegex.firstMatch(in: file, range: NSRange(file.startIndex..., in: file)) {
                    let range = match.range(at: 1)
                    let fileNumber = (file as NSString).substring(with: range)
                    outputFiles[fileNumber] = file
                }
            }

            let sortedInputKeys = inputFiles.keys.sorted()

            for key in sortedInputKeys {
                let inputFrame = cachesDirectory.appendingPathComponent(inputFiles[key]!)
                var outputFrame: URL? = nil
                if let outputFileName = outputFiles[key] {
                    outputFrame = cachesDirectory.appendingPathComponent(outputFileName)
                }

                frames.append(Frame(index: index, inputUrl: inputFrame, outputUrl: outputFrame))
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
                                frames.append(Frame(index: index, inputUrl: path, outputUrl: nil))
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
