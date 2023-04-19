//
//  StableDiffusionStore.swift
//  Pokora
//
//  Created by PJ Gray on 3/23/23.
//

import Foundation
import CoreGraphics
import StableDiffusion
import CoreML
import UniformTypeIdentifiers

class StableDiffusionStore {
    enum RunError: Error {
        case resources(String)
        case saving(String)
    }

    static func process(imageUrl: URL, strength: Float, seed: UInt32) throws -> URL? {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine
        let resourceURL = URL(filePath: "model_output/Resources")

        let pipeline = try StableDiffusionPipeline(resourcesAt: resourceURL,
                                                   configuration: config,
                                                   disableSafety: true,
                                                   reduceMemory: false)
        try pipeline.loadResources()

        var finalPrompt = "a cyberpunk cityscape"
        if let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, nil), let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
            var pipelineConfig = StableDiffusionPipeline.Configuration(prompt: finalPrompt)

            pipelineConfig.negativePrompt = ""
            pipelineConfig.startingImage = cgImage
            pipelineConfig.strength = strength
            pipelineConfig.imageCount = 1
            pipelineConfig.stepCount = 30
            pipelineConfig.seed = seed
            pipelineConfig.guidanceScale = 7.5
            
            do {
                let images = try pipeline.generateImages(configuration: pipelineConfig)
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

            } catch {
                print("CAUGHT ERROR IN GENERATE IMAGES...")
            }
        }
        return nil
    }
}