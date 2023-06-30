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
        config.computeUnits = .cpuAndGPU

        print("Initializing pipeline...")
        var controlNet: [String] = []

        if FileManager().fileExists(atPath: resourceURL.appendingPathComponent("controlnet").path(percentEncoded: false)) {
            let controlNetModels = try FileManager().contentsOfDirectory(atPath: resourceURL.appendingPathComponent("controlnet").path(percentEncoded: false))
            if let firstModel = controlNetModels.filter({ $0.hasSuffix("mlmodelc") }).first?.components(separatedBy: ".").first {
                controlNet = [ firstModel ]
                usingControlNet = true
            } else {
                usingControlNet = false
            }
        }
        
        self.pipeline = try StableDiffusionPipeline(resourcesAt: resourceURL,
                                                    controlNet: controlNet,
                                                    configuration: config,
                                                    disableSafety: true,
                                                    reduceMemory: false)
        try self.pipeline?.loadResources()
    }
    
    internal func processImageToImage(withImageUrl imageUrl: URL, toOutputUrl outputUrl: URL, prompt: String, strength: Float, seed: UInt32, stepCount: Int, rotateDirection: Effect.RotateDirection?, rotateAngle: Float?, zoomScale: Float?, progressHandler: (StableDiffusionPipeline.Progress) -> Bool = { _ in true }) throws -> URL? {
        
        if let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, nil), let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
            
            var startingImage = cgImage
            if let rotateDirection = rotateDirection, let rotateAngle = rotateAngle, let rotatedImage = self.rotateImage(image: cgImage, rotateDirection: CGFloat(rotateDirection.rawValue), rotateAngle: CGFloat(rotateAngle)) {
                if let zoomScale = zoomScale, let zoomedImage = self.zoomInImage(image: rotatedImage, scale: CGFloat(zoomScale)) {
                    startingImage = zoomedImage
                }
            }

            
            var pipelineConfig = StableDiffusionPipeline.Configuration(prompt: prompt)

            pipelineConfig.controlNetInputs = usingControlNet ? [startingImage] : []
            pipelineConfig.negativePrompt = "watermark"
            pipelineConfig.startingImage = startingImage
            pipelineConfig.strength = strength
            pipelineConfig.imageCount = 1
            pipelineConfig.stepCount = stepCount
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

    func processPreview(imageUrl: URL, prompt: String, strength: Float, seed: UInt32, stepCount: Int, rotateDirection: Effect.RotateDirection?, rotateAngle: Float?, zoomScale: Float?, modelURL: URL?) async throws -> CGImage? {
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
            
            var startingImage = cgImage
            if let rotateDirection = rotateDirection, let rotateAngle = rotateAngle, let rotatedImage = self.rotateImage(image: cgImage, rotateDirection: CGFloat(rotateDirection.rawValue), rotateAngle: CGFloat(rotateAngle)) {
                if let zoomScale = zoomScale, let zoomedImage = self.zoomInImage(image: rotatedImage, scale: CGFloat(zoomScale)) {
                    startingImage = zoomedImage
                }
            }

            var pipelineConfig = StableDiffusionPipeline.Configuration(prompt: prompt)

            pipelineConfig.controlNetInputs = usingControlNet ? [startingImage] : []
            pipelineConfig.negativePrompt = "watermark"
            pipelineConfig.startingImage = startingImage
            pipelineConfig.strength = strength
            pipelineConfig.imageCount = 1
            pipelineConfig.stepCount = stepCount
            pipelineConfig.seed = seed
            pipelineConfig.guidanceScale = 7.5
            
            print("Calling generateImages()")
            if let images = try pipeline?.generateImages(configuration: pipelineConfig, progressHandler: { progress in
                sampleTimer.stop()
                DispatchQueue.main.async {
                    if self.usingControlNet {
                        self.processingStatus = "Step #\(progress.step) of #\(progress.stepCount) using ControlNet"
                    } else {
                        self.processingStatus = "Step #\(progress.step) of #\(progress.stepCount)"
                    }
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
