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
    var duration: Float64?
    var framerate: Float?
}

let testvideo = Video(url: nil)
