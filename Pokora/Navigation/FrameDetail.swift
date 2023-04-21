//
//  FrameDetail.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

// ok so, pass in a binding to the frame
// i have a mock processed frame
struct FrameDetail: View {
    var frameIndex: Int
    @ObservedObject var store: VideoStore
    @State private var showProcessed = false

    var body: some View {
        let url = showProcessed ? store.video.frames[frameIndex-1].processed.url ?? store.video.frames[frameIndex-1].url : store.video.frames[frameIndex-1].url
        VStack {
            FrameImageView(imageUrl: url, emptyStateString: "No frame loaded")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack {
                Text("Prompt: ")
                    .fixedSize()
                TextField("Enter prompt here...", text: $store.video.frames[frameIndex-1].processed.prompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            HStack {
                Text("Strength: ")
                    .fixedSize()
                TextField("0.0 to 1.0", text: $store.video.frames[frameIndex-1].processed.strengthString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            HStack {
                Text("Seed: ")
                    .fixedSize()
                TextField("", text: $store.video.frames[frameIndex-1].processed.seedString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                Toggle(isOn: $showProcessed) {
                    Label("Show Processed Image", systemImage: "sparkles")
                }
                .toggleStyle(.button)
                .disabled(store.video.frames[frameIndex-1].processed.url == nil)
                Menu("Process") {
                    Button("Process All") {
                    }
                } primaryAction: {
                    if store.pipeline == nil {
                        do {
                            try store.initializePipeline()
                        } catch let error {
                            print("ERROR INIT PIPELINE: \(error)")
                        }
                    }
                    if let url = store.video.frames[frameIndex-1].url {
                        var processedFrame = ProcessedFrame(seed: store.video.frames[frameIndex-1].processed.seed, prompt: store.video.frames[frameIndex-1].processed.prompt, strength: store.video.frames[frameIndex-1].processed.strength)
                        do {
                            processedFrame.url = try store.process(imageUrl: url, prompt: store.video.frames[frameIndex-1].processed.prompt, strength: store.video.frames[frameIndex-1].processed.strength, seed: store.video.frames[frameIndex-1].processed.seed)
                            store.video.frames[frameIndex-1].processed = processedFrame
                            showProcessed = true
                        } catch let error {
                            print(error)
                        }
                    } else {
                        print("Error during processing")
                    }
                }
                .menuStyle(.button)
            }
        }
    }
}

struct FrameDetail_Previews: PreviewProvider {
    static var previews: some View {
        FrameDetail(frameIndex: 1, store: VideoStore(video: Video()))
    }
}
