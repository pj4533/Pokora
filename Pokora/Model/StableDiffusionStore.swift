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

class StableDiffusionStore {
    static func process(imageUrl: URL) throws {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine
        let resourceURL = URL(filePath: "model_output/Resources")

        let pipeline = try StableDiffusionPipeline(resourcesAt: resourceURL,
                                                   configuration: config,
                                                   disableSafety: true,
                                                   reduceMemory: false)
        try pipeline.loadResources()

        var finalPrompt = "a space cat"
        if let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, nil), let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
            var pipelineConfig = StableDiffusionPipeline.Configuration(prompt: finalPrompt)

            pipelineConfig.negativePrompt = ""
            pipelineConfig.startingImage = cgImage
            pipelineConfig.strength = 0.5
            pipelineConfig.imageCount = 1
            pipelineConfig.stepCount = 30
            pipelineConfig.seed = 123
            pipelineConfig.guidanceScale = 7.5
            
            
            
            
            
// Older commented out code -- while i figure out above
//            pipelineConfig.schedulerType =
            
//            // only output keyframes is turned on...
//            if !keyframes || (keyframes && (numFramesThisBlend == 0) && !strengthLFOGoingUp) || (video == "none") {
//                var finished = false
//                while !finished {
                    do {
                        let images = try pipeline.generateImages(configuration: pipelineConfig)
//                            progressHandler: { progress in
//                                sampleTimer.stop()
//                                handleProgress(progress,sampleTimer)
//                                if progress.stepCount != progress.step {
//                                    sampleTimer.start()
//                                }
//                                return true
//                            })
//                        finished = true
//                        _ = try saveImages(images, logNames: true)
                    } catch {
                        print("CAUGHT ERROR IN GENERATE IMAGES...")
                    }
//                }
//            }
        
        
        
        
        }
    }
}
