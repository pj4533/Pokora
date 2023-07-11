//
//  Effect.swift
//  Pokora
//
//  Created by PJ Gray on 4/30/23.
//

import Foundation

let globalSeed = UInt32.random(in: 0...UInt32.max)

struct Effect: Identifiable, Codable {
    enum EffectType: String, Codable, CaseIterable {
        case direct
        case generative
        case audioReactive
    }
    
    enum RotateDirection: Float, Codable {
        case clockwise = 1.0
        case counterclockwise = -1.0
    }
    enum RenderDirection: Codable {
        case forward
        case reverse
    }

    var id = UUID()
    var startFrame: Int
    var endFrame: Int
    
    var startStrength: Float = 0.2
    var endStrength: Float = 0.2
    var seed: UInt32 = globalSeed
    var stepCount: Int? = 30
    var prompt: String = "a cyberpunk cityscape"
    var effectType: EffectType? = .direct
    
    var rotateDirection: RotateDirection? = nil
    var rotateAngle: Float? = nil
    var zoomScale: Float? = nil
    var threshold: Float? = 0.7

    var renderDirection: RenderDirection? = .forward
    
    var numberFramesToProcess: Int {
        (endFrame - startFrame) + 1
    }
    
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
    
    init(effectType: Effect.EffectType, startFrame: Int, endFrame: Int, startStrength: Float, endStrength: Float, seed: UInt32, stepCount: Int, prompt: String, rotateDirection: RotateDirection? = nil, rotateAngle: Float? = nil, zoomScale: Float? = nil, renderDirection: RenderDirection = .forward, threshold: Float = 0.7) {
        self.id = UUID()
        self.effectType = effectType
        self.startFrame = startFrame
        self.endFrame = endFrame
        self.startStrength = startStrength
        self.endStrength = endStrength
        self.seed = seed
        self.stepCount = stepCount
        self.prompt = prompt
        self.rotateAngle = rotateAngle
        self.rotateDirection = rotateDirection
        self.zoomScale = zoomScale
        self.renderDirection = renderDirection
        self.threshold = threshold
    }
    
    // Ease of use for copying
    init(from existingEffect: Effect) {
        self.id = existingEffect.id
        self.effectType = existingEffect.effectType
        self.startFrame = existingEffect.startFrame
        self.endFrame = existingEffect.endFrame
        self.startStrength = existingEffect.startStrength
        self.endStrength = existingEffect.endStrength
        self.seed = existingEffect.seed
        self.stepCount = existingEffect.stepCount
        self.prompt = existingEffect.prompt
        self.rotateAngle = existingEffect.rotateAngle
        self.rotateDirection = existingEffect.rotateDirection
        self.zoomScale = existingEffect.zoomScale
        self.renderDirection = existingEffect.renderDirection
        self.threshold = existingEffect.threshold
    }
}
