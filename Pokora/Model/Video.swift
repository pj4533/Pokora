//
//  Video.swift
//  Pokora
//
//  Created by PJ Gray on 2/23/23.
//

import Foundation

struct Video: Identifiable, Equatable {
    var id = UUID()
    var url: URL?
    var frames: [Frame] = []
}

let testvideo = Video(url: nil, frames: [
    Frame(index: 1),
    Frame(index: 2),
    Frame(index: 3),
    Frame(index: 4),
    Frame(index: 5)
])
