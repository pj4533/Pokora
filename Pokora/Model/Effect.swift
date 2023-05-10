//
//  Effect.swift
//  Pokora
//
//  Created by PJ Gray on 4/30/23.
//

import Foundation

let globalSeed = UInt32.random(in: 0...UInt32.max)

struct Effect: Identifiable {
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
}
