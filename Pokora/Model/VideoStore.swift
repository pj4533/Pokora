//
//  VideoStore.swift
//  Pokora
//
//  Created by PJ Gray on 2/24/23.
//

import Foundation
import AVFoundation

let testStore = VideoStore(video: testvideo)
let emptyStore = VideoStore(video: Video())

class VideoStore: ObservableObject {
    @Published var video: Video
    @Published var effects: [Effect] = []
    @Published var player: AVPlayer?

    init(video: Video) {
        self.video = video
    }
        
    func loadVideo(url: URL) async {
        let localVideo = Video(url: url)
        await MainActor.run {
            self.player = AVPlayer(url: url)
            self.video = localVideo
        }
    }
}

