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

    var body: some View {
        VStack {
            HStack {
                FrameImageView(imageUrl: store.video?.frames[frameIndex-1].url, emptyStateString: "No frame loaded")
                Button("Process") {
                    if let url = store.video?.frames[frameIndex-1].url, let strength = Float(strengthString) {
                        var processedFrame = ProcessedFrame(seed: seed, prompt: prompt, strength: strength)
                        do {
                            processedFrame.url = try store.process(imageUrl: url, prompt: prompt, strength: strength, seed: seed)
                            store.video?.frames[frameIndex-1].processed = processedFrame
                        } catch let error {
                            print(error)
                        }                        
                    } else {
                        print("Error during processing")
                    }
                }
                .frame(width: 80.0)
                FrameImageView(imageUrl: store.video?.frames[frameIndex-1].processed?.url, emptyStateString: "Frame not processed")
            }
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
    }
}

struct FrameDetail_Previews: PreviewProvider {
    static var previews: some View {
        FrameDetail(frameIndex: 1, store: VideoStore())
    }
}
