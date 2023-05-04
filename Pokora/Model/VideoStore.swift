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
    @Published var currentFrameNumber: Int?
    @Published var isExtracting: Bool = false
    @Published var isExporting: Bool = false
    @Published var isProcessing: Bool = false
    @Published var shouldProcess = true
    @Published var showProcessed = false
    @Published var processingStatus = ""
    @Published var timingStatus = ""

    internal var pipeline: StableDiffusionPipeline?
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

