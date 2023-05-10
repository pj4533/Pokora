//
//  VideoStore+Effects.swift
//  Pokora
//
//  Created by PJ Gray on 4/30/23.
//

import Foundation

extension VideoStore {
    
    func addEffect(prompt: String, startStrength: Float, endStrength: Float, seed: UInt32) async {
        let currentFrame = currentFrameNumber ?? 0
        let lastFrame = lastFrameIndex ?? currentFrame
        let newEffect = Effect(startFrame: currentFrame, endFrame: lastFrame, startStrength: startStrength, endStrength: endStrength, seed: seed, prompt: prompt)
        return await MainActor.run {
            // Find the index of the next effect in the array
            if let nextEffectIndex = effects.firstIndex(where: { $0.startFrame > currentFrame }) {
                // Update the endFrame of the previous effect if it exists
                if nextEffectIndex > 0 {
                    let previousEffect = effects[nextEffectIndex - 1]
                    let updatedPreviousEffect = Effect(id: previousEffect.id, startFrame: previousEffect.startFrame, endFrame: currentFrame - 1, startStrength: previousEffect.startStrength, endStrength: previousEffect.endStrength, seed: previousEffect.seed, prompt: previousEffect.prompt)
                    effects[nextEffectIndex - 1] = updatedPreviousEffect
                }
                // Set the endFrame of the new effect to be right before the next effect's startFrame
                var updatedNewEffect = Effect(id: newEffect.id, startFrame: newEffect.startFrame, endFrame: effects[nextEffectIndex].startFrame - 1)
                updatedNewEffect.prompt = prompt
                updatedNewEffect.startStrength = startStrength
                updatedNewEffect.endStrength = endStrength
                updatedNewEffect.seed = seed
                // Insert the new effect at the correct position
                effects.insert(updatedNewEffect, at: nextEffectIndex)
            } else {
                // If there's no next effect, add the new effect to the end of the array
                if let lastEffect = effects.last {
                    let updatedLastEffect = Effect(id: lastEffect.id, startFrame: lastEffect.startFrame, endFrame: currentFrame - 1, startStrength: lastEffect.startStrength, endStrength: lastEffect.endStrength, seed: lastEffect.seed, prompt: lastEffect.prompt)
                    effects[effects.count - 1] = updatedLastEffect
                }
                effects.append(newEffect)
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
