//
//  VideoStore+Effects.swift
//  Pokora
//
//  Created by PJ Gray on 4/30/23.
//

import Foundation

extension VideoStore {
    
    func addEffect() async {
        let currentFrame = await currentFrameNumber() ?? 0
        let lastFrame = await lastFrameIndex() ?? currentFrame
        let newEffect = Effect(startFrame: currentFrame, endFrame: lastFrame)

        await MainActor.run {
            // Find the index of the next effect in the array
            if let nextEffectIndex = effects.firstIndex(where: { $0.startFrame > currentFrame }) {
                // Update the endFrame of the previous effect if it exists
                if nextEffectIndex > 0 {
                    let previousEffect = effects[nextEffectIndex - 1]
                    let updatedPreviousEffect = Effect(id: previousEffect.id, startFrame: previousEffect.startFrame, endFrame: currentFrame - 1)
                    effects[nextEffectIndex - 1] = updatedPreviousEffect
                }
                // Set the endFrame of the new effect to be right before the next effect's startFrame
                let updatedNewEffect = Effect(id: newEffect.id, startFrame: newEffect.startFrame, endFrame: effects[nextEffectIndex].startFrame - 1)
                // Insert the new effect at the correct position
                effects.insert(updatedNewEffect, at: nextEffectIndex)
            } else {
                // If there's no next effect, add the new effect to the end of the array
                if let lastEffect = effects.last {
                    let updatedLastEffect = Effect(id: lastEffect.id, startFrame: lastEffect.startFrame, endFrame: currentFrame - 1)
                    effects[effects.count - 1] = updatedLastEffect
                }
                effects.append(newEffect)
            }
        }
    }
}
