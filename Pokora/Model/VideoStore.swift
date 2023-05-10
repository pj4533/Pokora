//
//  VideoStore.swift
//  Pokora
//
//  Created by PJ Gray on 2/24/23.
//

import Foundation
import AVFoundation
import StableDiffusion
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let pokoraProject = UTType(exportedAs: "com.saygoodnight.Pokora.project")
}

final class VideoStore: ReferenceFileDocument {
    @Published var project: PokoraProject
    
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

    typealias Snapshot = PokoraProject

    static var readableContentTypes: [UTType] { [.pokoraProject] }
    
    func snapshot(contentType: UTType) throws -> PokoraProject {
        project
    }
    
    init() {
        project = PokoraProject(video: Video())
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.project = try JSONDecoder().decode(PokoraProject.self, from: data)
    }

    func fileWrapper(snapshot: PokoraProject, configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(snapshot)
        return FileWrapper(regularFileWithContents: data)
    }

    deinit {
        removeTimeObserver()
    }        
}

