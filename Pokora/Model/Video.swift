//
//  Video.swift
//  Pokora
//
//  Created by PJ Gray on 2/23/23.
//

import Foundation
import AVKit

struct Video: Codable, Identifiable {
    var id = UUID()
    var url: URL
    var frames: [Frame] = []
}

let testvideo = Video(url: URL(string: "file:///Users/pgray/Downloads/Testdata/waitingforyou.mov")!, frames: [
    Frame(index: 1, inputUrl: URL(string: "file:///Users/pgray/Downloads/Testdata/inputframes/out1.png")!),
    Frame(index: 2, inputUrl: URL(string: "file:///Users/pgray/Downloads/Testdata/inputframes/out2.png")!),
    Frame(index: 3, inputUrl: URL(string: "file:///Users/pgray/Downloads/Testdata/inputframes/out3.png")!),
    Frame(index: 4, inputUrl: URL(string: "file:///Users/pgray/Downloads/Testdata/inputframes/out4.png")!),
    Frame(index: 5, inputUrl: URL(string: "file:///Users/pgray/Downloads/Testdata/inputframes/out5.png")!)
])

extension Video {
    init(url: URL) {
        self.url = url
    }
    
    mutating func add(frame: Frame) {
        frames.append(frame)
    }
}
