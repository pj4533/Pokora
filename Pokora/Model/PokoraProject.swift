//
//  PokoraProject.swift
//  Pokora
//
//  Created by PJ Gray on 5/10/23.
//

import SwiftUI

struct PokoraProject: Codable {
    var video: Video
    var effects: [Effect] = []

    init(video: Video) {
        self.video = video
    }
}
