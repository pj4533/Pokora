//
//  PokoraProject+Effects.swift
//  Pokora
//
//  Created by PJ Gray on 5/10/23.
//

import Foundation

extension PokoraProject {
    func lastFrameOfEffect(withStartFrame startFrame: Int) -> Int {
        let lastFrame = video.lastFrameIndex ?? startFrame
        // Find the index of the next effect in the array
        if let nextEffectIndex = effects.firstIndex(where: { $0.startFrame > startFrame }) {
            return effects[nextEffectIndex].startFrame - 1
        }
        
        return lastFrame
    }
    
    @MainActor mutating func addEffect(effectType: Effect.EffectType, startFrame: Int, prompt: String, negativePrompt: String, startStrength: Float, endStrength: Float, seed: UInt32, stepCount: Int, rotateDirection: Effect.RotateDirection?, rotateAngle: Float?, zoomScale: Float?, renderDirection: Effect.RenderDirection, threshold: Float) {
        let currentFrame = startFrame
        let lastFrame = video.lastFrameIndex ?? currentFrame
        let newEffect = Effect(effectType: effectType, startFrame: currentFrame, endFrame: lastFrame, startStrength: startStrength, endStrength: endStrength, seed: seed, stepCount: stepCount, prompt: prompt, negativePrompt: negativePrompt, rotateDirection: rotateDirection, rotateAngle: rotateAngle, zoomScale: zoomScale, renderDirection: renderDirection, threshold: threshold)

        // Find the index of the next effect in the array
        if let nextEffectIndex = effects.firstIndex(where: { $0.startFrame > newEffect.startFrame }) {
            // Update the endFrame of the previous effect if it exists
            if nextEffectIndex > 0 {
                effects[nextEffectIndex - 1].endFrame = newEffect.startFrame - 1
            }
            // Set the endFrame of the new effect to be right before the next effect's startFrame
            var updatedNewEffect = Effect(from: newEffect)
            updatedNewEffect.endFrame = effects[nextEffectIndex].startFrame - 1

            // Insert the new effect at the correct position
            effects.insert(updatedNewEffect, at: nextEffectIndex)
        } else {
            // If there's no next effect, add the new effect to the end of the array
            if let lastEffect = effects.last {
                var updatedLastEffect = Effect(from: lastEffect)
                updatedLastEffect.endFrame = newEffect.startFrame - 1
                effects[effects.count - 1] = updatedLastEffect
            }
            effects.append(newEffect)
        }
    }
    
    @MainActor mutating func updateEffects() {
        for thisEffect in effects {
            if let thisIndex = effects.firstIndex(where: { $0.id == thisEffect.id }) {
                if let nextIndex = effects.firstIndex(where: { $0.startFrame > thisEffect.startFrame } ) {
                    effects[thisIndex].endFrame = effects[nextIndex].startFrame - 1
                } else {
                    effects[thisIndex].endFrame = video.lastFrameIndex ?? effects[thisIndex].endFrame
                }
            } else {
                print("ERROR updating effects")
            }
        }
    }
    
    func hasEffect(atFrameIndex frameIndex: Int) -> Bool {
        for effect in effects {
            if effect.startFrame == frameIndex {
                return true
            }
        }
        return false
    }
    
    mutating func clearProcessedFrames(withEffect effect: Effect) {
        for index in 0...(video.lastFrameIndex ?? 0) {
            if (index >= effect.startFrame) && (index <= effect.endFrame) {
                let fileManager = FileManager.default
                if let url = video.frames?[index].processedUrl {
                    do {
                        try fileManager.removeItem(atPath: url.path)
                    } catch let error {
                        print("ERROR: \(error.localizedDescription)")
                    }
                }
                video.frames?[index].processedUrl = nil
            }
        }
    }
    
    func getUrls(from effect: Effect) -> [URL] {
        guard let frames = video.frames else {
            return []
        }
        
        let startFrame = effect.startFrame
        let endFrame = effect.endFrame
        
        var urls: [URL] = []
        
        for frame in frames where frame.index >= startFrame && frame.index <= endFrame {
            if let url = frame.processedUrl {
                urls.append(url)
            }
        }
        
        return urls
    }
}
