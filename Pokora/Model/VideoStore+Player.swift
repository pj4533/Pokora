//
//  VideoStore+Player.swift
//  Pokora
//
//  Created by PJ Gray on 4/30/23.
//

import Foundation
import AVFoundation

extension VideoStore {
    var lastFrameIndex: Int? {
        guard let frameRate = video.framerate, let duration = video.duration else {
            return nil
        }
        return Int(round(duration * Double(frameRate)))
    }
    
    internal func updateCurrentFrameNumber() {
         guard let player = player, let frameRate = video.framerate else {
             currentFrameNumber = nil
             return
         }
         let currentTime = CMTimeGetSeconds(player.currentTime())
         currentFrameNumber = Int(round(currentTime * Double(frameRate)))
     }
}
