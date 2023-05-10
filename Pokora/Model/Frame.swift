//
//  Frame.swift
//  Pokora
//
//  Created by PJ Gray on 5/3/23.
//

import Foundation

struct Frame: Identifiable, Codable {
    var id = UUID()
    var index: Int
    var url: URL?
    var processedUrl: URL?
}
