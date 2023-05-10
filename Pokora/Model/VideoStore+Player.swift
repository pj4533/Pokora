//
//  VideoStore+Player.swift
//  Pokora
//
//  Created by PJ Gray on 4/30/23.
//

import Foundation
import AVFoundation

extension VideoStore {
    internal func updateCurrentFrameNumber() {
        guard let player = player, let frameRate = project.video.framerate else {
             currentFrameNumber = nil
             return
         }
         let currentTime = CMTimeGetSeconds(player.currentTime())
         currentFrameNumber = Int(round(currentTime * Double(frameRate)))
     }
}
