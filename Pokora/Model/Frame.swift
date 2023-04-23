//
//  Frame.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import Foundation

struct Frame: Identifiable {
    var id = UUID()
    var index: Int
    var url: URL?
    var processed: ProcessedFrame = ProcessedFrame(seed: 123, prompt: "", strength: 0.2)
}

struct ProcessedFrame {
    var url: URL?
    var seed: UInt32
    var prompt: String
    var strength: Float    
}

extension Frame {
    static var placeholder: Frame {
        Frame(index: 1)
    }
}
