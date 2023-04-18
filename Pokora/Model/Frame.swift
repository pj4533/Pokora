//
//  Frame.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import Foundation
import CoreGraphics
import AVKit

struct Frame: Codable, Identifiable, Hashable {
    var id = UUID()
    var index: Int
    var inputUrl: URL
    var outputUrl: URL?
}

extension Frame {
    static var placeholder: Self {
        Frame(index: 1, inputUrl: URL(string: "file:///Users/pgray/Downloads/Testdata/inputframes/out1.png")!)
    }    
}
