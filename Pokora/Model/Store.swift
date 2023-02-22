//
//  Store.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import Foundation

class Store: ObservableObject {
    @Published var frames: [Frame] = [
        Frame(id: 1),
        Frame(id: 2),
        Frame(id: 3),
        Frame(id: 4),
        Frame(id: 5)
    ]
    
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
