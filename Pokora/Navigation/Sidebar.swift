//
//  Sidebar.swift
//  Pokora
//
//  Created by PJ Gray on 2/23/23.
//

import SwiftUI
import AVKit

struct Sidebar: View {
    @State var video: Video?
    var body: some View {
        VStack {
            Button("Select File") {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                if panel.runModal() == .OK, let url = panel.url {
                    loadVideo(url: url)
                }
            }
            List {
                ForEach(video?.frames ?? []) { frame in
                    NavigationLink {
                        FrameDetail(frame: frame)
                    } label: {
                        Label("Frame #\(frame.index)", systemImage: "video.square.fill")
                    }
                }
            }
        }
    }
    
    // this shouldn't live here, but not sure how where it should go in this declarative world
    func loadVideo(url: URL) {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        do {
            let asset = AVAsset(url: url)
            let reader = try AVAssetReader(asset: asset)
            
            asset.loadTracks(withMediaType: .video) { tracks, error in
                do {
                    if let videoTrack = tracks?[0] {
                        // read video frames as BGRA
                        let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])

                        reader.add(trackReaderOutput)
                        reader.startReading()

                        var frames: [Frame] = []
                        var index = 1
                        
                        // this is how you get the number of frames, but the non async version is deprecated.
//                        print("TRACK: \(Int(videoTrack.timeRange.duration.seconds * Double(videoTrack.nominalFrameRate)))")
                        while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
                            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                                let ciimage = CIImage(cvImageBuffer: imageBuffer)
                                let path = cachesDirectory.appendingPathComponent("out\(index).png")
                                print("\(path.absoluteString)")
                                if let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) {
                                    let format = CIFormat.RGBA8
                                    let context = CIContext()
                                    try context.writePNGRepresentation(of: ciimage, to: path, format: format, colorSpace: colorSpace)
                                }
                                frames.append(Frame(index: index, inputUrl: path))
                            }
                            index += 1
                        }
                        video = Video(url: url, frames: frames)
                    } else {
                        print("didn't get tracks")
                    }
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }

}

struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar(video: testvideo)
    }
}

