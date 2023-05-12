//
//  VideoStore+Uprez.swift
//  Pokora
//
//  Created by PJ Gray on 5/12/23.
//

import Foundation
import Vision
import VideoToolbox
import UniformTypeIdentifiers
import AVKit

extension VideoStore {
    
    func uprez(pngURLs: [URL]) async throws {
        await MainActor.run {
            isUprezzing = true
        }

        if let modelUrl = Bundle.main.url(forResource: "realesrgan512", withExtension: "mlmodelc") {
            let uprezModel = try MLModel(contentsOf: modelUrl)
            let model = try VNCoreMLModel(for: uprezModel)

            let coreMLRequest = VNCoreMLRequest(model: model)
            coreMLRequest.imageCropAndScaleOption = .scaleFill
            for url in pngURLs {
                await MainActor.run {
                    self.timingStatus = "[ \(url.lastPathComponent) of \(pngURLs.count) ]"
                }

                guard let videoSize = NSImage(contentsOf: url)?.size else {
                    throw NSError(domain: "Error getting image size", code: -1, userInfo: nil)
                }
                if videoSize.width == 512 {
                    let handler = VNImageRequestHandler(url: url)
                    try handler.perform([coreMLRequest])
                    if let result = coreMLRequest.results?.first as? VNPixelBufferObservation {
                        var cgImage: CGImage?
                        VTCreateCGImageFromCVPixelBuffer(result.pixelBuffer, options: nil, imageOut: &cgImage)
                        if let image = cgImage {
                            guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
                                throw RunError.saving("Failed to create destination for \(url)")
                            }
                            CGImageDestinationAddImage(dest, image, nil)
                            if !CGImageDestinationFinalize(dest) {
                                throw RunError.saving("Failed to save \(url)")
                            }
                            print("Uprezzed: \(url.lastPathComponent)")
                        }
                    }
                } else {
                    print("Skipped, already uprezzed: \(url.lastPathComponent)")
                }
            }
        } else {
            throw RunError.uprezzing("Failed to find model file")
        }
        await MainActor.run {
            isUprezzing = false
        }
    }
}
