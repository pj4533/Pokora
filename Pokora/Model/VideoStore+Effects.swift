//
//  VideoStore+Effects.swift
//  Pokora
//
//  Created by PJ Gray on 5/18/23.
//

import Foundation
import StableDiffusion

extension VideoStore {
    func processEffects(modelURL: URL?) async {
        await MainActor.run {
            self.shouldProcess = true
            self.isProcessing = true
        }
        for effect in project.effects {
            do {
                try await self.process(effect: effect, modelURL: modelURL)
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                }
            }
            if !self.shouldProcess { break }
        }
        await MainActor.run {
            self.isProcessing = false
        }
    }

    private func process(effect: Effect, modelURL: URL?) async throws {
        if pipeline == nil {
            await MainActor.run {
                self.timingStatus = ""
                self.showThumbnails = false
                self.processingStatus = "Initializing Pipeline..."
            }
            if let url = modelURL {
                try initializePipeline(resourceURL: url)
            } else {
                try initializePipeline()
            }
        }

        for frameIndex in effect.startFrame...effect.endFrame {
            var url: URL?
            if effect.effectType == .direct {
                url = project.video.frames?[frameIndex].url
            } else if effect.effectType == .generative {
                if frameIndex == 0 {
                    url = project.video.frames?[frameIndex].url
                } else if let previousProcessedUrl = project.video.frames?[frameIndex-1].processedUrl {
                    url = previousProcessedUrl
                } else if let previousUrl = project.video.frames?[frameIndex-1].url {
                    url = previousUrl
                } else {
                    print("Could not find previous frame for generative processing at index \(frameIndex - 1)...")
                }
            }
            if let url = url {
                let sampleTimer = SampleTimer()
                sampleTimer.start()

                await MainActor.run {
                    let totalNumberFramesToProcess = project.effects.map({ $0.numberFramesToProcess }).reduce(0, +)
                    let framesProcessed = project.video.frames?.compactMap { $0.processedUrl }.count ?? 0
                    
                    self.processingStatus = "\(totalNumberFramesToProcess - framesProcessed) frames remaining..."
                }
                
                let cachesDirectory = try project.getProjectCacheDirectory()
                let fileURL = cachesDirectory.appendingPathComponent("out\(String(format: "%05d", frameIndex))_processed.png")
                if !FileManager().fileExists(atPath: fileURL.path) {
                    let processedUrl = try processImageToImage(withImageUrl: url,
                                                               toOutputUrl: fileURL,
                                                     prompt: effect.prompt,
                                                   strength: effect.strength(forFrameIndex: frameIndex),
                                                               seed: effect.effectType == .direct ? effect.seed : UInt32.random(in: 0...UInt32.max),
                                                               rotateDirection: effect.effectType == .direct ? nil : 1.0,
                                                               zoomScale: effect.effectType == .direct ? nil : 1.001,
                                                       progressHandler: { progress in
                        sampleTimer.stop()
                        DispatchQueue.main.async {
                            self.showThumbnails = true
                            let totalNumberFramesToProcess = self.project.effects.map({ $0.numberFramesToProcess }).reduce(0, +)
                            let framesProcessed = self.project.video.frames?.compactMap { $0.processedUrl }.count ?? 0
                            self.processingStatus = "Step #\(progress.step) of #\(progress.stepCount) (\(totalNumberFramesToProcess - framesProcessed) frames remaining)"
                            self.timingStatus = "[ \(String(format: "mean: %.2f, median: %.2f, last %.2f", 1.0/sampleTimer.mean, 1.0/sampleTimer.median, 1.0/sampleTimer.allSamples.last!)) ] step/sec"
                        }

                        if progress.stepCount != progress.step {
                            sampleTimer.start()
                        }
                        return shouldProcess
                    })
                    await MainActor.run {
                        project.video.frames?[frameIndex].processedUrl = processedUrl
                    }
                } else {
                    await MainActor.run {
                        print("INDEX: \(frameIndex)")
                        project.video.frames?[frameIndex].processedUrl = fileURL
                    }
                }

            } else {
                print("ERROR: should be an effect on #\(frameIndex), but didn't find url")
            }
            if !self.shouldProcess { break }
        }
    }
}
