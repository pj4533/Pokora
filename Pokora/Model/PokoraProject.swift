//
//  PokoraProject.swift
//  Pokora
//
//  Created by PJ Gray on 5/10/23.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let pokoraProject = UTType(exportedAs: "com.saygoodnight.Pokora.project")
}

struct PokoraProject: FileDocument, Codable {
    var video: Video
    var effects: [Effect] = []

    init(video: Video) {
        self.video = video
    }

    static var readableContentTypes: [UTType] { [.pokoraProject] }

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents!
        self = try JSONDecoder().decode(Self.self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(self)
        return FileWrapper(regularFileWithContents: data)
    }
}
