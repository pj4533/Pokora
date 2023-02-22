//
//  Frame.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import Foundation
import CoreGraphics
import AVKit

struct Frame: Codable, Identifiable {
    var id: Int
    var inputMovieUrl: URL?
}

extension Frame {
    static var placeholder: Self {
        Frame(id: 0, inputMovieUrl: URL(string: "file:///Users/pgray/Downloads/66uprez_raw.mov"))
    }
    
    func image() async throws -> CGImage? {
        print("reading image")
        if let url = inputMovieUrl {
            print("have url")
            return try await imageFromVideo(url: url, at: Double(self.id))
        }
        print("image is nil")
        return nil
    }
    
    private func imageFromVideo(url: URL, at time: TimeInterval) async throws -> CGImage {
        try await withCheckedThrowingContinuation({ continuation in
            DispatchQueue.global(qos: .background).async {
                let asset = AVURLAsset(url: url)
                
                let assetIG = AVAssetImageGenerator(asset: asset)
                assetIG.appliesPreferredTrackTransform = true
                assetIG.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels
                
                let cmTime = CMTime(seconds: time, preferredTimescale: 60)
                let thumbnailImageRef: CGImage
                do {
                    thumbnailImageRef = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
                } catch {
                    print(error.localizedDescription)
                    continuation.resume(throwing: error)
                    return
                }
                print("returning image")
                continuation.resume(returning: thumbnailImageRef)
            }
        })
    }
}
