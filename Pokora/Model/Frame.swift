//
//  Frame.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import Foundation

struct Frame: Codable, Identifiable {
    var id: Int
}

extension Frame {
    static var placeholder: Self {
        Frame(id: 0)
    }
}
