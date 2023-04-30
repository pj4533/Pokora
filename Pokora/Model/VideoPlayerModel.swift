//
//  VideoPlayerModel.swift
//  Pokora
//
//  Created by PJ Gray on 4/30/23.
//

import Foundation
import AVFoundation

class VideoPlayerModel: ObservableObject {
    @Published var player: AVPlayer
    
    init(url: URL) {
        self.player = AVPlayer(url: url)
    }
    
    func currentFrameNumber() async -> Int? {
        do {
            guard let currentItem = player.currentItem, let frameRate = try await currentItem.asset.loadTracks(withMediaType: .video).first?.load(.nominalFrameRate) else {
                return nil
            }
            let currentTime = CMTimeGetSeconds(player.currentTime())
            return Int(round(currentTime * Double(frameRate)))
        } catch {
            return nil
        }
    }
}
