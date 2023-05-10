//
//  PokoraApp.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

@main
struct PokoraApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: PokoraProject(video: Video())) { file in
            ContentView(store: VideoStore(project: file.document))
        }
    }
}
