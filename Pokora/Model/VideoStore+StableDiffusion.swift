//
//  VideoStore+StableDiffusion.swift
//  Pokora
//
//  Created by PJ Gray on 5/3/23.
//

import CoreGraphics
import StableDiffusion
import CoreML
import UniformTypeIdentifiers

extension VideoStore {
    
    private func initializePipeline(resourceURL: URL = URL(filePath: "model_output/Resources")) throws {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine

        print("Initializing pipeline...")
        self.pipeline = try StableDiffusionPipeline(resourcesAt: resourceURL,
                                                   configuration: config,
                                                   disableSafety: true,
                                                   reduceMemory: false)
        try self.pipeline?.loadResources()
    }
    
    private func process(imageUrl: URL, prompt: String, strength: Float, seed: UInt32, progressHandler: (StableDiffusionPipeline.Progress) -> Bool = { _ in true }) throws -> URL? {
        if let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, nil), let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
            var pipelineConfig = StableDiffusionPipeline.Configuration(prompt: prompt)

            pipelineConfig.negativePrompt = ""
            pipelineConfig.startingImage = cgImage
            pipelineConfig.strength = strength
            pipelineConfig.imageCount = 1
            pipelineConfig.stepCount = 30
            pipelineConfig.seed = seed
            pipelineConfig.guidanceScale = 7.5
            
            print("Calling generateImages()")
            if let images = try pipeline?.generateImages(configuration: pipelineConfig, progressHandler: progressHandler) {
                for i in 0 ..< images.count {
                    if let image = images[i] {
                        let name = (imageUrl.lastPathComponent.components(separatedBy: ".").first ?? "").appending("_processed.png")
                        let fileURL = imageUrl.deletingLastPathComponent().appending(path:name)

                        guard let dest = CGImageDestinationCreateWithURL(fileURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
                            throw RunError.saving("Failed to create destination for \(fileURL)")
                        }

                        CGImageDestinationAddImage(dest, image, nil)
                        if !CGImageDestinationFinalize(dest) {
                            throw RunError.saving("Failed to save \(fileURL)")
                        }
                        
                        return fileURL
                    }
                }
            }
        }
        return nil
    }

    internal func process(frame: Frame, atIndex index: Int, modelURL: URL?) async throws {
        if pipeline == nil {
            await MainActor.run {
                self.timingStatus = ""
                self.processingStatus = "Initializing Pipeline..."
            }
            if let url = modelURL {
                try initializePipeline(resourceURL: url)
            } else {
                try initializePipeline()
            }
        }
        // TODO: The timing stuff here creates a dependency on StableDiffusion directly
        // I'd rather have this abstracted behind a generic interface so other types
        // of filters would work easily, and still be able to provide timing information.
        //
        // Added to Issue #35
        if let url = frame.url, let effect = project.effects.first(where: { index >= $0.startFrame && index <= $0.endFrame }) {
            let sampleTimer = SampleTimer()
            sampleTimer.start()

            await MainActor.run {
                self.processingStatus = "Processing Frame #\(index) of #\((project.video.frames?.count ?? 0)-1)..."
            }
            
            // kind of a hack, should pre-load this
            let name = (url.lastPathComponent.components(separatedBy: ".").first ?? "").appending("_processed.png")
            let fileURL = url.deletingLastPathComponent().appending(path:name)
            if !FileManager().fileExists(atPath: fileURL.path) {
                let processedUrl = try process(imageUrl: url,
                                                 prompt: effect.prompt,
                                               strength: effect.strength(forFrameIndex: index),
                                                   seed: effect.seed,
                                                   progressHandler: { progress in
                    sampleTimer.stop()
                    DispatchQueue.main.async {
                        self.processingStatus = "Frame #\(index) - Step #\(progress.step) of #\(progress.stepCount)"
                        self.timingStatus = "[ \(String(format: "mean: %.2f, median: %.2f, last %.2f", 1.0/sampleTimer.mean, 1.0/sampleTimer.median, 1.0/sampleTimer.allSamples.last!)) ] step/sec"
                    }

                    if progress.stepCount != progress.step {
                        sampleTimer.start()
                    }
                    return shouldProcess
                })
                await MainActor.run {
                    project.video.frames?[index].processedUrl = processedUrl
                }
            } else {
                await MainActor.run {
                    project.video.frames?[index].processedUrl = fileURL
                }
            }

        } else {
            print("No effect on frame \(index)")
        }
    }
}
