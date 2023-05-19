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
    
    internal func initializePipeline(resourceURL: URL = URL(filePath: "model_output/Resources")) throws {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine

        print("Initializing pipeline...")
        self.pipeline = try StableDiffusionPipeline(resourcesAt: resourceURL,
                                                   configuration: config,
                                                   disableSafety: true,
                                                   reduceMemory: false)
        try self.pipeline?.loadResources()
    }
    
    internal func processImageToImage(withImageUrl imageUrl: URL, toOutputUrl outputUrl: URL, prompt: String, strength: Float, seed: UInt32, rotateDirection: CGFloat?, zoomScale: CGFloat?, progressHandler: (StableDiffusionPipeline.Progress) -> Bool = { _ in true }) throws -> URL? {
        if let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, nil), let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
            var startingImage = cgImage
//            if let rotateDirection = rotateDirection, let rotatedImage = self.rotateImage(image: startingImage, rotateDirection: rotateDirection, rotateAngle: 0.2) {
//                startingImage = rotatedImage
//            }
//            if let zoomScale = zoomScale, let zoomedImage = self.zoomInImage(image: startingImage, scale: zoomScale) {
//                startingImage = zoomedImage
//            }
            var pipelineConfig = StableDiffusionPipeline.Configuration(prompt: prompt)

            pipelineConfig.negativePrompt = ""
            pipelineConfig.startingImage = startingImage
            pipelineConfig.strength = strength
            pipelineConfig.imageCount = 1
            pipelineConfig.stepCount = 30
            pipelineConfig.seed = seed
            pipelineConfig.guidanceScale = 7.5
            
            print("Calling generateImages()")
            if let images = try pipeline?.generateImages(configuration: pipelineConfig, progressHandler: progressHandler) {
                for i in 0 ..< images.count {
                    if let image = images[i] {
                        guard let dest = CGImageDestinationCreateWithURL(outputUrl as CFURL, UTType.png.identifier as CFString, 1, nil) else {
                            throw RunError.saving("Failed to create destination for \(outputUrl)")
                        }

                        CGImageDestinationAddImage(dest, image, nil)
                        if !CGImageDestinationFinalize(dest) {
                            throw RunError.saving("Failed to save \(outputUrl)")
                        }
                        
                        return outputUrl
                    }
                }
            }
        }
        return nil
    }

    func processPreview(imageUrl: URL, prompt: String, strength: Float, seed: UInt32, modelURL: URL?) async throws -> CGImage? {
        await MainActor.run {
            self.showThumbnails = false
            self.shouldProcess = true
            self.isProcessing = true
        }

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
        
        let sampleTimer = SampleTimer()
        sampleTimer.start()

        await MainActor.run {
            self.processingStatus = "Generating preview..."
        }
        
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
            if let images = try pipeline?.generateImages(configuration: pipelineConfig, progressHandler: { progress in
                sampleTimer.stop()
                DispatchQueue.main.async {
                    self.processingStatus = "Step #\(progress.step) of #\(progress.stepCount)"
                    self.timingStatus = "[ \(String(format: "mean: %.2f, median: %.2f, last %.2f", 1.0/sampleTimer.mean, 1.0/sampleTimer.median, 1.0/sampleTimer.allSamples.last!)) ] step/sec"
                }

                if progress.stepCount != progress.step {
                    sampleTimer.start()
                }
                return shouldProcess
            }) {
                for i in 0 ..< images.count {
                    if let image = images[i] {
                        await MainActor.run {
                            self.isProcessing = false
                        }
                        return image
                    }
                }
            }
        }
        await MainActor.run {
            self.isProcessing = false
        }
        return nil
    }    
}
