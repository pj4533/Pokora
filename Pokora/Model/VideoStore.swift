//
//  VideoStore.swift
//  Pokora
//
//  Created by PJ Gray on 2/24/23.
//

import Foundation

let testStore = VideoStore(video: testvideo)
let emptyStore = VideoStore(video: Video())

class VideoStore: ObservableObject {
    @Published var video: Video
    
    init(video: Video) {
        self.video = video
    }
        
    // some legacy code here
    func loadVideo(url: URL) async {
        let localVideo = Video(url: url)
        await MainActor.run {
            self.video = localVideo
        }
    }
}

