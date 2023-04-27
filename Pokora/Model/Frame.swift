//
//  Frame.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import Foundation

let globalSeed = UInt32.random(in: 0...UInt32.max)

struct Frame: Identifiable, Hashable {
    var id = UUID()
    var index: Int
    var url: URL?
    var processed: ProcessedFrame = ProcessedFrame(seed: globalSeed, prompt: "A cyberpunk cityscape", strength: 0.2)
}

struct ProcessedFrame: Hashable {
    var url: URL?
    var seed: UInt32
    var prompt: String
    var strength: Float

    var seedString: String {
        get {
            String(seed)
        }
        set {
            if let newSeed = UInt32(newValue) {
                seed = newSeed
            }
        }
    }
}

extension Frame {
    static var placeholder: Frame {
        Frame(index: 1)
    }
}
