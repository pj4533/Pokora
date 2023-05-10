//
//  Effect.swift
//  Pokora
//
//  Created by PJ Gray on 4/30/23.
//

import Foundation

let globalSeed = UInt32.random(in: 0...UInt32.max)

struct Effect: Identifiable, Codable {
    var id = UUID()
    var startFrame: Int
    var endFrame: Int
    
    var startStrength: Float = 0.2
    var endStrength: Float = 0.2
    var seed: UInt32 = globalSeed
    var prompt: String = "a cyberpunk cityscape"
    
    func strength(forFrameIndex index: Int) -> Float {
        if startStrength == endStrength {
            return startStrength
        } else {
            if endFrame == startFrame {
                // To avoid division by zero
                return startStrength
            }
            let progress = Float(index - startFrame) / Float(endFrame - startFrame)
            return startStrength + progress * (endStrength - startStrength)
        }
    }
    
    init(startFrame: Int, endFrame: Int) {
        self.startFrame = startFrame
        self.endFrame = endFrame
    }
    
    init(startFrame: Int, endFrame: Int, startStrength: Float, endStrength: Float, seed: UInt32, prompt: String) {
        self.id = UUID()
        self.startFrame = startFrame
        self.endFrame = endFrame
        self.startStrength = startStrength
        self.endStrength = endStrength
        self.seed = seed
        self.prompt = prompt
    }
    
    // Ease of use for copying
    init(from existingEffect: Effect) {
        self.id = existingEffect.id
        self.startFrame = existingEffect.startFrame
        self.endFrame = existingEffect.endFrame
        self.startStrength = existingEffect.startStrength
        self.endStrength = existingEffect.endStrength
        self.seed = existingEffect.seed
        self.prompt = existingEffect.prompt
    }
}
