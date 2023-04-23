//
//  FrameDetailToolbar.swift
//  Pokora
//
//  Created by PJ Gray on 4/23/23.
//

import SwiftUI
import StableDiffusion

struct FrameDetailToolbar: View {
    @Binding var frame: Frame
    @ObservedObject var store: VideoStore
    @Binding var showProcessedFrame: Bool
    @Binding var isProcessing: Bool
    @Binding var processingStatus: String
    @Binding var timingStatus: String

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
                    // TODO: The timing stuff here creates a dependency on StableDiffusion directly
                    // I'd rather have this abstracted behind a generic interface so other types
                    // of filters would work easily, and still be able to provide timing information.
                    // Added to Issue #35
                    let sampleTimer = SampleTimer()
                    sampleTimer.start()

                    var processedFrame = ProcessedFrame(seed: frame.processed.seed, prompt: frame.processed.prompt, strength: frame.processed.strength)
                    print("PRE-PROCESSED: \(processedFrame)")
                    processingStatus = "Processing Frame..."
                    do {
                        processedFrame.url = try store.process(imageUrl: url,
                                                               prompt: processedFrame.prompt,
                                                               strength: processedFrame.strength,
                                                               seed: processedFrame.seed,
                                                               progressHandler: { progress in
                            sampleTimer.stop()
                            processingStatus = "Step #\(progress.step) of #\(progress.stepCount)"
                            timingStatus = "[ \(String(format: "mean: %.2f, median: %.2f, last %.2f", 1.0/sampleTimer.mean, 1.0/sampleTimer.median, 1.0/sampleTimer.allSamples.last!)) ] step/sec"

                            if progress.stepCount != progress.step {
                                sampleTimer.start()
                            }
                            return true
                        })
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
        FrameDetailToolbar(frame: $placeholderFrame, store: testStore, showProcessedFrame: .constant(false), isProcessing: .constant(false), processingStatus: .constant("Loading"), timingStatus: .constant("Timing Data"))
    }
}
