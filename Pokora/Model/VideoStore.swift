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
    @Published var currentFrameNumber: Int?
    @Published var isExtracting: Bool = false
    @Published var isExporting: Bool = false

    internal var timeObserverToken: Any?
    
    init(video: Video) {
        self.video = video
    }
    
    deinit {
        removeTimeObserver()
    }        
}

