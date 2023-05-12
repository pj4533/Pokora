//
//  PokoraProject.swift
//  Pokora
//
//  Created by PJ Gray on 5/10/23.
//

import SwiftUI

struct PokoraProject: Codable {
    var video: Video
    var effects: [Effect] = []

    init(video: Video) {
        self.video = video
    }
    
    func getProjectCacheDirectory() throws -> URL {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let projectDirectory = cacheDirectory.appendingPathComponent(video.id.uuidString)

        // If the directory does not exist, this method creates it.
        // This method is only available in macOS 10.7 and iOS 5.0 or later.
        try FileManager.default.createDirectory(at: projectDirectory, withIntermediateDirectories: true, attributes: nil)

        return projectDirectory
    }
}
