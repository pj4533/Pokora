//
//  Frame.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import Foundation
import CoreGraphics
import AVKit

class Frame: ObservableObject, Identifiable, Hashable {
    var id = UUID()
    var index: Int
    @Published var inputUrl: URL?
    @Published var outputUrl: URL?

    init(id: UUID = UUID(), index: Int, inputUrl: URL?, outputUrl: URL?) {
        self.id = id
        self.index = index
        self.inputUrl = inputUrl
        self.outputUrl = outputUrl
    }

    static func ==(lhs: Frame, rhs: Frame) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Frame {
    static var placeholder: Frame {
        Frame(index: 1, inputUrl: nil, outputUrl: nil)
    }
}
