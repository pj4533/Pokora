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
    
    internal var timeObserverToken: Any?
    
    init(video: Video) {
        self.video = video
    }
    
    deinit {
        removeTimeObserver()
    }
        
    func loadVideo(url: URL) async throws {
        let localVideo = Video(url: url)
        let player = AVPlayer(url: url)
        let framerate = try await player.currentItem?.asset.loadTracks(withMediaType: .video).first?.load(.nominalFrameRate)
        if let durationTime = try await player.currentItem?.asset.load(.duration) {
            let duration = CMTimeGetSeconds(durationTime)

            await MainActor.run {
                self.player = player
                self.video = localVideo
                self.video.framerate = framerate
                self.video.duration = duration
            }
            
            addTimeObserver()
        }
    }
}

