//
//  VideoStore+Player.swift
//  Pokora
//
//  Created by PJ Gray on 4/30/23.
//

import Foundation
import AVFoundation

extension VideoStore {
    func cueTo(frame: Int) {
        let time = CMTime(value: Int64(frame), timescale: Int32(project.video.framerate ?? 0.0))
        player?.seek(to: time)
    }
    
    internal func updateCurrentFrameNumber() {
        guard let player = player, let frameRate = project.video.framerate else {
             currentFrameNumber = nil
             return
         }
         let currentTime = CMTimeGetSeconds(player.currentTime())
         currentFrameNumber = Int(round(currentTime * Double(frameRate)))
     }
}
