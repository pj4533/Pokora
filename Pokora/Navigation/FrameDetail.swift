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
    
    @State private var strengthString = "0.2"
    @State private var seedString = "\(UInt32.random(in: 0...UInt32.max))"

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
                TextField("0.0 to 1.0", text: $strengthString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        if let strength = Float(strengthString) {
                            store.video.frames[frameIndex-1].processed.strength = strength
                        }
                    }
                    .onChange(of: store.video.frames[frameIndex-1].processed.strength, perform: { newValue in
                        strengthString = "\(newValue)"
                    })
            }
            HStack {
                Text("Seed: ")
                    .fixedSize()
                TextField("", text: $seedString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        if let seed = UInt32(seedString) {
                            store.video.frames[frameIndex-1].processed.seed = seed
                        }
                    }
                    .onChange(of: store.video.frames[frameIndex-1].processed.seed, perform: { newValue in
                        seedString = "\(newValue)"
                    })
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
                        print("PRE-PROCESSED: \(processedFrame)")
                        do {
                            processedFrame.url = try store.process(imageUrl: url, prompt: processedFrame.prompt, strength: processedFrame.strength, seed: processedFrame.seed)
                            store.video.frames[frameIndex-1].processed = processedFrame
                            print("PROCESSED: \(store.video.frames[frameIndex-1].processed)")
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
