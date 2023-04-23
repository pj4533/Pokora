//
//  FrameDetailToolbar.swift
//  Pokora
//
//  Created by PJ Gray on 4/23/23.
//

import SwiftUI

struct FrameDetailToolbar: View {
    @Binding var frame: Frame
    @ObservedObject var store: VideoStore
    @Binding var showProcessedFrame: Bool
    @Binding var isProcessing: Bool
    @Binding var processingStatus: String

    var body: some View {
        Toggle(isOn: $showProcessedFrame) {
            Label("Show Processed Image", systemImage: "sparkles")
        }
        .toggleStyle(.button)
        .disabled(frame.processed.url == nil)
        Menu("Process") {
            Button("Process All") {
            }
        } primaryAction: {
            processingStatus = "Initializing Pipeline..."
            isProcessing = true
            DispatchQueue.global().async {
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
                    processingStatus = "Processing Frame..."
                    do {
                        processedFrame.url = try store.process(imageUrl: url, prompt: processedFrame.prompt, strength: processedFrame.strength, seed: processedFrame.seed)
                        DispatchQueue.main.async {
                            isProcessing = false
                            frame.processed = processedFrame
                            print("PROCESSED: \(frame.processed)")
                            showProcessedFrame = true
                        }
                    } catch let error {
                        DispatchQueue.main.async {
                            isProcessing = false
                            print(error)
                        }
                    }
                } else {
                    print("Error during processing")
                }
            }
        }
        .menuStyle(.button)
    }
}

struct FrameDetailToolbar_Previews: PreviewProvider {
    @State static private var placeholderFrame = Frame.placeholder

    static var previews: some View {
        FrameDetailToolbar(frame: $placeholderFrame, store: testStore, showProcessedFrame: .constant(false), isProcessing: .constant(false), processingStatus: .constant("Loading"))
    }
}
