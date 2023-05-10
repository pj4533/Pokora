//
//  Video.swift
//  Pokora
//
//  Created by PJ Gray on 2/23/23.
//

import Foundation

struct Video: Identifiable, Codable {
    var id = UUID()
    var bookmarkData: Data?
    var duration: Float64?
    var framerate: Float?
    var frames: [Frame]?
    
    var lastFrameIndex: Int? {
        guard let frameRate = framerate, let duration = duration else {
            return nil
        }
        return Int(round(duration * Double(frameRate)))
    }
}

let testvideo = Video(bookmarkData: nil)
