//
//  FrameDetail.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

struct FrameDetail: View {
    var frameIndex: Int
    @State private var prompt = "A cyberpunk cityscape"
    @State private var strengthString = "0.2"
    let seed: UInt32 = UInt32.random(in: 0...UInt32.max)
    @ObservedObject var store: VideoStore
    @State private var showProcessed = false

    var body: some View {
        let url = showProcessed ? store.video?.frames[frameIndex-1].processed?.url ?? store.video?.frames[frameIndex-1].url : store.video?.frames[frameIndex-1].url
        VStack {
            FrameImageView(imageUrl: url, emptyStateString: "No frame loaded")
            HStack {
                Text("Prompt: ")
                    .fixedSize()
                TextField("A cyberpunk cityscape", text: $prompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            HStack {
                Text("Strength: ")
                    .fixedSize()
                TextField("0.5", text: $strengthString)
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
                .disabled(store.video?.frames[frameIndex-1].processed?.url == nil)
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
                    if let url = store.video?.frames[frameIndex-1].url, let strength = Float(strengthString) {
                        var processedFrame = ProcessedFrame(seed: seed, prompt: prompt, strength: strength)
                        do {
                            processedFrame.url = try store.process(imageUrl: url, prompt: prompt, strength: strength, seed: seed)
                            store.video?.frames[frameIndex-1].processed = processedFrame
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
        FrameDetail(frameIndex: 1, store: VideoStore())
    }
}
