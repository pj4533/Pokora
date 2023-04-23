//
//  VideoStore+StableDiffusion.swift
//  Pokora
//
//  Created by PJ Gray on 4/20/23.
//

import Foundation
import CoreGraphics
import StableDiffusion
import CoreML
import UniformTypeIdentifiers

extension VideoStore {
    
    func initializePipeline() throws {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine
        let resourceURL = URL(filePath: "model_output/Resources")

        print("Initializing pipeline...")
        self.pipeline = try StableDiffusionPipeline(resourcesAt: resourceURL,
                                                   configuration: config,
                                                   disableSafety: true,
                                                   reduceMemory: false)
        try self.pipeline?.loadResources()
    }
    
    func process(imageUrl: URL, prompt: String, strength: Float, seed: UInt32, progressHandler: (StableDiffusionPipeline.Progress) -> Bool = { _ in true }) throws -> URL? {
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
            do {
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
            } catch {
                print("CAUGHT ERROR IN GENERATE IMAGES...")
            }
        }
        return nil
    }

}
