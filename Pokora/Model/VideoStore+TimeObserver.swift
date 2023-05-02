//
//  VideoStore+TimeObserver.swift
//  Pokora
//
//  Created by PJ Gray on 5/1/23.
//

import Foundation
import AVFoundation

extension VideoStore {
    internal func addTimeObserver() {
        let interval = CMTime(seconds: 1.0 / 60.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] _ in
            self?.updateCurrentFrameNumber()
        }
    }
    
    internal func removeTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
}
