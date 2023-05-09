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
    
    var strength: Float = 0.2
    var seed: UInt32 = globalSeed
    var prompt: String = "a cyberpunk cityscape"
}
