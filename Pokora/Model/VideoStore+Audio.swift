//
//  VideoStore+Audio.swift
//  Pokora
//
//  Created by PJ Gray on 7/8/23.
//

import Foundation
import AVFoundation

extension VideoStore {
    
    func getNumberOfTransientsWithThreshold(threshold: Float) async throws -> Int {
        let transients = self.project.video.amplitudes?.filter({ $0 > threshold })
        return transients?.count ?? 0
    }
    
    func getAverageAmplitudes() async throws -> [Float] {
        var amplitudes = [Float]()
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
                    let asset = AVAsset(url: bookmarkedURL)
                    guard let track = try await asset.loadTracks(withMediaType: .audio).first else {
                        throw NSError(domain: "AudioTrackError", code: 0, userInfo: nil)
                    }
                    
                    let assetReaderSettings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatLinearPCM,
                        AVLinearPCMIsBigEndianKey: false,
                        AVLinearPCMIsFloatKey: false,
                        AVLinearPCMBitDepthKey: 16
                    ]
                    
                    let assetReaderOutput = AVAssetReaderTrackOutput(track: track, outputSettings: assetReaderSettings)
                    assetReaderOutput.alwaysCopiesSampleData = false
                    
                    let assetReader = try AVAssetReader(asset: asset)
                    assetReader.add(assetReaderOutput)
                    assetReader.startReading()
                    
                    // Get the sample rate from the track
                    let sampleRate = try await Double(track.load(.naturalTimeScale))
                    // Get the frame rate from the video track
                    guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                        throw NSError(domain: "VideoTrackError", code: 0, userInfo: nil)
                    }
                    let frameRate = try await videoTrack.load(.nominalFrameRate)
                    let samplesPerFrame = sampleRate / Double(frameRate)
                    
                    var totalSampleCount = 0
                    var allValues = [Int16]()
                    while assetReader.status == .reading {
                        if let sampleBuffer = assetReaderOutput.copyNextSampleBuffer(),
                           let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                            let size = CMBlockBufferGetDataLength(blockBuffer)
                            var data = Data(count: size)
                            
                            data.withUnsafeMutableBytes { bytes in
                                if let baseAddress = bytes.baseAddress {
                                    CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: size, destination: baseAddress)
                                }
                            }
                            
                            let values = data.withUnsafeBytes {
                                Array(UnsafeBufferPointer<Int16>(start: $0.bindMemory(to: Int16.self).baseAddress, count: data.count / 2))
                            }
                            allValues += values
                            totalSampleCount += values.count
                        }
                    }
                    
                    // Compute start and end sample counts
                    let secondsDuration = try await Int(CMTimeGetSeconds(asset.load(.duration)))
                    let frameCount: Int = Int(Float(secondsDuration) * frameRate)
                    for frame in 0..<frameCount {
                        let startSample = Int(Double(frame) * samplesPerFrame)
                        let endSample = min(Int(Double(frame + 1) * samplesPerFrame), totalSampleCount)
                        
                        var dataSum: Int64 = 0
                        var dataCount: Int = 0
                        
                        for i in stride(from: startSample, to: endSample, by: 1) {
                            let mono = allValues[i]
                            dataSum += Int64(mono) * Int64(mono)
                            dataCount += 1
                        }
                        
                        if dataCount > 0 {
                            let rms = sqrt(Float(dataSum) / Float(dataCount))
                            let normalizedRms = rms / 32767.0
                            print("Frame #\(frame): \(normalizedRms)")
                            amplitudes.append(normalizedRms)
                        }
                        else {
                            throw NSError(domain: "NoDataError", code: 0, userInfo: nil)
                        }
                    }
                }
                // Make sure to stop accessing the resource when you're done
                bookmarkedURL.stopAccessingSecurityScopedResource()
            }
        }
        return amplitudes
    }

    
    func getAverageAmplitudeAtFrame(frame: Int) async throws -> Float {
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
                    let time = CMTime(value: Int64(frame), timescale: Int32(project.video.framerate ?? 0.0))
                    let asset = AVAsset(url: bookmarkedURL)
                    guard let track = try await asset.loadTracks(withMediaType: .audio).first else {
                        throw NSError(domain: "AudioTrackError", code: 0, userInfo: nil)
                    }
                    
                    let assetReaderSettings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatLinearPCM,
                        AVLinearPCMIsBigEndianKey: false,
                        AVLinearPCMIsFloatKey: false,
                        AVLinearPCMBitDepthKey: 16
                    ]
                    
                    let assetReaderOutput = AVAssetReaderTrackOutput(track: track, outputSettings: assetReaderSettings)
                    assetReaderOutput.alwaysCopiesSampleData = false
                    
                    let assetReader = try AVAssetReader(asset: asset)
                    assetReader.add(assetReaderOutput)
                    assetReader.startReading()
                    
                    // Get the sample rate from the track
                    let sampleRate = try await Double(track.load(.naturalTimeScale))
                    
                    // Compute start and end sample counts
                    let timeSample = Int(CMTimeGetSeconds(time) * sampleRate)
                    let windowSamples = Int(0.04 * sampleRate) // 30ms? ....10 milliseconds window
//                    let startSample = max(timeSample - windowSamples / 2, 0)
                    let startSample = max(timeSample, 0)
                    let endSample = startSample + windowSamples
                    
                    var dataSum: Int64 = 0
                    var dataCount: Int = 0
                    var currentSample = 0
                    
                    while assetReader.status == .reading {
                        if let sampleBuffer = assetReaderOutput.copyNextSampleBuffer(),
                           let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                            let size = CMBlockBufferGetDataLength(blockBuffer)
                            var data = Data(count: size)
                            
                            data.withUnsafeMutableBytes { bytes in
                                if let baseAddress = bytes.baseAddress {
                                    CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: size, destination: baseAddress)
                                }
                            }
                            
                            let values = data.withUnsafeBytes {
                                Array(UnsafeBufferPointer<Int16>(start: $0.bindMemory(to: Int16.self).baseAddress, count: data.count / 2))
                            }
                            
                            for i in stride(from: 0, to: values.count, by: 2) {
                                if currentSample >= startSample && currentSample < endSample {
                                    let mono = Int16((Int(values[i]) + Int(values[i + 1])) / 2)
                                    dataSum += Int64(mono) * Int64(mono)
                                    dataCount += 1
                                }
                                currentSample += 1
                            }
                        }
                    }

                    // Make sure to stop accessing the resource when you're done
                    bookmarkedURL.stopAccessingSecurityScopedResource()

                    if dataCount > 0 {
                        let rms = sqrt(Float(dataSum) / Float(dataCount))
                        let normalizedRms = rms / 32767.0
                        return normalizedRms
                    }
                    else {
                        throw NSError(domain: "NoDataError", code: 0, userInfo: nil)
                    }
                    
                }
            }
        }
        return 0.0
    }

    // Can prob delete this...
    func getPeakAmplitudePerFrame(frame: Int) async throws -> Float {
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
                    let time = CMTime(value: Int64(frame), timescale: Int32(project.video.framerate ?? 0.0))
                    let asset = AVAsset(url: bookmarkedURL)
                    guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first,
                          let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                        throw NSError(domain: "TrackError", code: 0, userInfo: nil)
                    }
                    
                    // Get the frame duration and sample rate
                    let frameDuration = try await videoTrack.load(.minFrameDuration)
                    let sampleRate = try await Double(audioTrack.load(.naturalTimeScale))
                    
                    let assetReaderSettings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatLinearPCM,
                        AVLinearPCMIsBigEndianKey: false,
                        AVLinearPCMIsFloatKey: false,
                        AVLinearPCMBitDepthKey: 16
                    ]
                    
                    let assetReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: assetReaderSettings)
                    assetReaderOutput.alwaysCopiesSampleData = false
                    
                    let assetReader = try AVAssetReader(asset: asset)
                    assetReader.add(assetReaderOutput)
                    assetReader.startReading()
                    
                    // Compute start and end sample counts
                    let timeSample = Int(CMTimeGetSeconds(time) * sampleRate)
                    let frameSamples = Int(CMTimeGetSeconds(frameDuration) * sampleRate)
                    let startSample = timeSample
                    let endSample = startSample + frameSamples
                    
                    var peakAmplitude: Int16 = 0
                    var currentSample = 0
                    
                    while assetReader.status == .reading {
                        if let sampleBuffer = assetReaderOutput.copyNextSampleBuffer(),
                           let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                            let size = CMBlockBufferGetDataLength(blockBuffer)
                            var data = Data(count: size)
                            
                            data.withUnsafeMutableBytes { bytes in
                                if let baseAddress = bytes.baseAddress {
                                    CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: size, destination: baseAddress)
                                }
                            }
                            
                            let values = data.withUnsafeBytes {
                                Array(UnsafeBufferPointer<Int16>(start: $0.bindMemory(to: Int16.self).baseAddress, count: data.count / 2))
                            }
                            
                            for i in stride(from: 0, to: values.count, by: 2) {
                                if currentSample >= startSample && currentSample < endSample {
                                    let mono = Int16(Int(values[i]) / 2 + Int(values[i + 1]) / 2)
                                    if mono != Int16.min {
                                        peakAmplitude = max(peakAmplitude, abs(mono))
                                    }
                                }
                                currentSample += 1
                            }
                        }
                    }

                    // Make sure to stop accessing the resource when you're done
                    bookmarkedURL.stopAccessingSecurityScopedResource()

                    // Return normalized peak amplitude
                    return Float(peakAmplitude) / 32767.0
                }
            }
        }
        return 0.0
    }
}
