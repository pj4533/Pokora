//
//  VideoStore.swift
//  Pokora
//
//  Created by PJ Gray on 2/24/23.
//

import Foundation
import AVFoundation
import StableDiffusion

let testStore = VideoStore(video: testvideo)
let emptyStore = VideoStore(video: Video())

class VideoStore: ObservableObject {
    @Published var video: Video
    @Published var effects: [Effect] = []
    @Published var player: AVPlayer?
    
    // This is the current frame the player is parked on
    @Published var currentFrameNumber: Int?
    
    // This is whether we are currently extracting frames
    @Published var isExtracting: Bool = false
    
    // This is whether we are currently exporting frames
    @Published var isExporting: Bool = false
    
    // This is whether we are currently processing frames
    @Published var isProcessing: Bool = false
    
    // This enables the cancel button on the status display
    @Published var shouldProcess = true
    
    // This is the primary status display string
    @Published var processingStatus = ""
    
    // This is the secondary status display string
    @Published var timingStatus = ""

    internal var pipeline: StableDiffusionPipeline?
    
    // This enables the update of the currently frame of the player
    internal var timeObserverToken: Any?
    
    enum RunError: Error {
        case resources(String)
        case saving(String)
        case processing(String)
    }

    init(video: Video) {
        self.video = video
    }
    
    deinit {
        removeTimeObserver()
    }        
}

