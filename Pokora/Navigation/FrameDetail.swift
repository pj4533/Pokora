//
//  FrameDetail.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

struct FrameDetail: View {
    @Binding var frame: Frame
    @ObservedObject var store: VideoStore
    @State private var showProcessed = false
    
    @State private var strength = 0.2
    @State private var seedString = "\(UInt32.random(in: 0...UInt32.max))"

    var body: some View {
        let url = showProcessed ? frame.processed.url ?? frame.url : frame.url
        VStack {
            FrameImageView(imageUrl: url, emptyStateString: "No frame loaded")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Form {
                Section {
                    TextField("Prompt", text: $frame.processed.prompt)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Stepper("Strength", value: $frame.processed.strength, step: 0.1, format: .number)
                    TextField("Seed", text: $seedString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            if let seed = UInt32(seedString) {
                                frame.processed.seed = seed
                            }
                        }
                        .onChange(of: frame.processed.seed, perform: { newValue in
                            seedString = "\(newValue)"
                        })
                }
            }
            .formStyle(.grouped)
            .frame(maxHeight: 160.0)
        }
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                Toggle(isOn: $showProcessed) {
                    Label("Show Processed Image", systemImage: "sparkles")
                }
                .toggleStyle(.button)
                .disabled(frame.processed.url == nil)
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
                    if let url = frame.url {
                        var processedFrame = ProcessedFrame(seed: frame.processed.seed, prompt: frame.processed.prompt, strength: frame.processed.strength)
                        print("PRE-PROCESSED: \(processedFrame)")
                        do {
                            processedFrame.url = try store.process(imageUrl: url, prompt: processedFrame.prompt, strength: processedFrame.strength, seed: processedFrame.seed)
                            frame.processed = processedFrame
                            print("PROCESSED: \(frame.processed)")
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
    @State static private var placeholderFrame = Frame.placeholder

    static var previews: some View {
        FrameDetail(frame: $placeholderFrame, store: VideoStore(video: Video()))
    }
}
