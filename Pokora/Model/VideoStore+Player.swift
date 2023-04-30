//
//  VideoStore+Player.swift
//  Pokora
//
//  Created by PJ Gray on 4/30/23.
//

import Foundation
import AVFoundation

extension VideoStore {
    func currentFrameNumber() async -> Int? {
        do {
            guard let player = player, let currentItem = player.currentItem, let frameRate = try await currentItem.asset.loadTracks(withMediaType: .video).first?.load(.nominalFrameRate) else {
                return nil
            }
            let currentTime = CMTimeGetSeconds(player.currentTime())
            return Int(round(currentTime * Double(frameRate)))
        } catch {
            return nil
        }
    }
    
    func lastFrameIndex() async -> Int? {
        do {
            guard let player = player, let currentItem = player.currentItem, let frameRate = try await currentItem.asset.loadTracks(withMediaType: .video).first?.load(.nominalFrameRate) else {
                return nil
            }
            let duration = try await CMTimeGetSeconds(currentItem.asset.load(.duration))
            return Int(round(duration * Double(frameRate))) - 1
        } catch {
            return nil
        }
    }
}
