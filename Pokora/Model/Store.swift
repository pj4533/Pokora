//
//  Store.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import Foundation

class Store: ObservableObject {
    @Published var frames: [Frame] = []
    @Published var movieFileUrl: URL?
        
    func readFrames() {
        frames = [
            Frame(id: 1, inputMovieUrl: movieFileUrl),
            Frame(id: 2, inputMovieUrl: movieFileUrl),
            Frame(id: 3, inputMovieUrl: movieFileUrl),
            Frame(id: 4, inputMovieUrl: movieFileUrl),
            Frame(id: 5, inputMovieUrl: movieFileUrl)
        ]
    }
    
    subscript(frameID: Frame.ID?) -> Frame {
        get {
            if let id = frameID {
                return frames.first(where: { $0.id == id }) ?? .placeholder
            }
            return .placeholder
        }

        set(newValue) {
            if let id = frameID {
                frames[frames.firstIndex(where: { $0.id == id })!] = newValue
            }
        }
    }
}
