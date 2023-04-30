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
}

let testvideo = Video(url: nil)
