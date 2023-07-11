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
        // process direct and audioreactive effects
        for effect in project.effects.filter({ ($0.effectType == .direct) || ($0.effectType == .audioReactive) }) {
            do {
                try await self.process(effect: effect, modelURL: modelURL)
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                }
            }
            if !self.shouldProcess {
                await MainActor.run {
                    self.isProcessing = false
                }
                return
            }
        }
        // then process generative effects -- this allows for reverse generative effects
        for effect in project.effects.filter({ $0.effectType == .generative }) {
            do {
                try await self.process(effect: effect, modelURL: modelURL)
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                }
            }
            if !self.shouldProcess {
                await MainActor.run {
                    self.isProcessing = false
                }
                return
            }
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

        var generativeSourceIndexOffset: Int
        if effect.renderDirection == .forward {
            generativeSourceIndexOffset = -1
        } else {
            generativeSourceIndexOffset = 1
        }
        let sequence = effect.renderDirection == .forward ? Array(effect.startFrame...effect.endFrame) : Array((effect.startFrame...effect.endFrame).reversed())
        
        //
        var currentStrength: Float = 0.0
        var currentEnvelopeFramesRemaining = 0
        let maxEnvelopeFrames = 15
        let maxStrength: Float = 0.9
        let threshhold: Float = effect.threshold ?? 1.0
        var effectSeed = effect.seed
        
        for frameIndex in sequence {
            var skipProcess = false

            var url: URL?
            if effect.effectType == .direct {
                // i dont think this is needed anymore, but for older files it is....?
                if frameIndex >= project.video.frames?.count ?? 0 {
                    break
                }
                url = project.video.frames?[frameIndex].url
            } else if effect.effectType == .audioReactive {
                url = project.video.frames?[frameIndex].url
            } else if effect.effectType == .generative {
                if (frameIndex == 0) && (effect.renderDirection == .forward) {
                    url = project.video.frames?[frameIndex].url
                } else if let processedUrl = project.video.frames?[frameIndex+generativeSourceIndexOffset].processedUrl {
                    url = processedUrl
                } else if let unprocessedUrl = project.video.frames?[frameIndex+generativeSourceIndexOffset].url {
                    url = unprocessedUrl
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
                
                if effect.effectType == .audioReactive {
                    // TODO: should use the stored amplitudes not get it again, but there might be an off by one error
                    let amplitudeAtFrame = try await self.getAverageAmplitudeAtFrame(frame: frameIndex)
                    if amplitudeAtFrame > threshhold {
                        if currentStrength == 0.0 {
                            // get a new seed only if previously we were not processing
                            effectSeed = UInt32.random(in: 0...UInt32.max)
                            print("NEW SEED: \(effectSeed)")
                        }
                        currentEnvelopeFramesRemaining = maxEnvelopeFrames
                        currentStrength = maxStrength
                        skipProcess = false
                    } else {
                        if currentEnvelopeFramesRemaining == 0 {
                            skipProcess = true
                            currentStrength = 0.0
                        } else {
                            currentEnvelopeFramesRemaining -= 1
                            
                            // linear
                            currentStrength -= (maxStrength / Float(maxEnvelopeFrames))
                        }
                    }
                    print("AUDIO AMPLITUDE FRAME \(frameIndex): \(amplitudeAtFrame) | currentStrength: \(currentStrength)")
                }
                
                if skipProcess {
                    await MainActor.run {
                        print("INDEX: \(frameIndex)")
                        project.video.frames?[frameIndex].processedUrl = project.video.frames?[frameIndex].url
                        project.video.frames?[frameIndex].processedTime = Date()
                    }
                } else {
                    // TODO: Don't like how strength is processed here for audio reactive effects - should be stored
                    // probably should adjust the strengthForFrameIndex function to account for audio reactive?
                    if !FileManager().fileExists(atPath: fileURL.path) {
                        let processedUrl = try processImageToImage(withImageUrl: url,
                                                                   toOutputUrl: fileURL,
                                                         prompt: effect.prompt,
                                                                   strength: effect.effectType == .audioReactive ? currentStrength : effect.strength(forFrameIndex: frameIndex),
                                                                   seed: effect.effectType == .generative ? UInt32.random(in: 0...UInt32.max) : effectSeed,
                                                                   stepCount: effect.stepCount ?? 30,
                                                                   rotateDirection: effect.rotateDirection,
                                                                   rotateAngle: effect.rotateAngle,
                                                                   zoomScale: effect.zoomScale,
                                                           progressHandler: { progress in
                            sampleTimer.stop()
                            DispatchQueue.main.async {
                                self.showThumbnails = true
                                let totalNumberFramesToProcess = self.project.effects.map({ $0.numberFramesToProcess }).reduce(0, +)
                                let framesProcessed = self.project.video.frames?.compactMap { $0.processedUrl }.count ?? 0
                                if self.usingControlNet {
                                    self.processingStatus = "Step #\(progress.step) of #\(progress.stepCount) using ControlNet (\(totalNumberFramesToProcess - framesProcessed) frames remaining)"
                                } else {
                                    self.processingStatus = "Step #\(progress.step) of #\(progress.stepCount) (\(totalNumberFramesToProcess - framesProcessed) frames remaining)"
                                }
                                self.timingStatus = "[ \(String(format: "mean: %.2f, median: %.2f, last %.2f", 1.0/sampleTimer.mean, 1.0/sampleTimer.median, 1.0/sampleTimer.allSamples.last!)) ] step/sec"
                            }

                            if progress.stepCount != progress.step {
                                sampleTimer.start()
                            }
                            return shouldProcess
                        })
                        await MainActor.run {
                            project.video.frames?[frameIndex].processedUrl = processedUrl
                            project.video.frames?[frameIndex].processedTime = Date()
                        }
                    } else {
                        await MainActor.run {
                            print("INDEX: \(frameIndex)")
                            project.video.frames?[frameIndex].processedUrl = fileURL
                            project.video.frames?[frameIndex].processedTime = Date()
                        }
                    }
                }
            } else {
                print("ERROR: should be an effect on #\(frameIndex), but didn't find url")
            }
            if !self.shouldProcess { break }
        }
    }
}
