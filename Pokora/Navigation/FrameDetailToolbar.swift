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
    @Binding var shouldProcess: Bool
    @ObservedObject var store: VideoStore
    @Binding var showProcessedFrame: Bool
    @Binding var isProcessing: Bool
    @Binding var processingStatus: String
    @Binding var timingStatus: String
    @Binding var modelURL: URL?
    
    @State private var showErrorDialog: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        Toggle(isOn: $showProcessedFrame) {
            Label("Show Processed Image", systemImage: "sparkles")
        }
        .toggleStyle(.button)
        .disabled(frame.processed.url == nil)
        Menu("Process") {
            Button("Process All") {
                shouldProcess = true
                processingStatus = "Initializing Pipeline..."
                isProcessing = true
                DispatchQueue.global().async {
                    let thisProcessedFrameValues = frame.processed
                    for (index, frame) in store.video.frames.enumerated() {
                        var newFrame = frame
                        newFrame.processed = thisProcessedFrameValues
                        do {
                            try process(frame: newFrame, atIndex: index)
                            DispatchQueue.main.async {
                                showProcessedFrame = true
                                isProcessing = false
                            }
                        } catch let error {
                            DispatchQueue.main.async {
                                showProcessedFrame = true
                                isProcessing = false
                                self.showErrorDialog(with: error)
                            }
                        }
                        if !shouldProcess { break }
                    }
                }
            }
        } primaryAction: {
            shouldProcess = true
            processingStatus = "Initializing Pipeline..."
            isProcessing = true
            DispatchQueue.global().async {
                if let index = store.video.frames.firstIndex(of: frame) {
                    do {
                        try process(frame: frame, atIndex: index)
                        DispatchQueue.main.async {
                            showProcessedFrame = true
                            isProcessing = false
                        }
                    } catch let error {
                        DispatchQueue.main.async {
                            showProcessedFrame = true
                            isProcessing = false
                            self.showErrorDialog(with: error)
                        }
                    }
                }
            }
        }
        .menuStyle(.button)
        Button("Export") {
            let panel = NSSavePanel()
            panel.nameFieldStringValue = "exported.mov"
            panel.canCreateDirectories = true
            panel.prompt = "Export"
            
            panel.begin { response in
                if response == .OK, let outputUrl = panel.url {
                    Task {
                        do {
                            if let url = store.video.url, let pngs = store.video.frames.map({$0.processed.url ?? $0.url}) as? [URL] {
                                let outputUrl = try await store.exportVideoWithPNGs(videoURL: url, pngURLs: pngs, outputURL: outputUrl)
                                print("OUTPUT: \(outputUrl)")
                            }
                        } catch let error {
                            print("ERROR EXPORTING: \(error)")
                        }
                    }
                }
            }
        }
        .alert(isPresented: $showErrorDialog) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK")) {
                    // Handle the dismiss action if needed
                }
            )
        }
    }
    
    func showErrorDialog(with error: Error) {
        self.errorMessage = error.localizedDescription
        self.showErrorDialog = true
    }
    
    func process(frame: Frame, atIndex index: Int) throws {
        if store.pipeline == nil {
            if let url = modelURL {
                try store.initializePipeline(resourceURL: url)
            } else {
                try store.initializePipeline()
            }
        }
        // TODO: The timing stuff here creates a dependency on StableDiffusion directly
        // I'd rather have this abstracted behind a generic interface so other types
        // of filters would work easily, and still be able to provide timing information.
        //
        // Added to Issue #35
        if let url = frame.url {
            let sampleTimer = SampleTimer()
            sampleTimer.start()

            var processedFrame = ProcessedFrame(seed: frame.processed.seed, prompt: frame.processed.prompt, strength: frame.processed.strength)
            processingStatus = "Processing Frame #\(index + 1) of #\(store.video.frames.count)..."
            processedFrame.url = try store.process(imageUrl: url,
                                                   prompt: processedFrame.prompt,
                                                   strength: processedFrame.strength,
                                                   seed: processedFrame.seed,
                                                   progressHandler: { progress in
                sampleTimer.stop()
                processingStatus = "Frame #\(index + 1) - Step #\(progress.step) of #\(progress.stepCount)"
                timingStatus = "[ \(String(format: "mean: %.2f, median: %.2f, last %.2f", 1.0/sampleTimer.mean, 1.0/sampleTimer.median, 1.0/sampleTimer.allSamples.last!)) ] step/sec"

                if progress.stepCount != progress.step {
                    sampleTimer.start()
                }
                return shouldProcess
            })

            DispatchQueue.main.async {
                store.video.frames[index].processed = processedFrame
            }
        } else {
            print("Error during processing")
        }
    }
}

struct FrameDetailToolbar_Previews: PreviewProvider {
    @State static private var placeholderFrame = Frame.placeholder

    static var previews: some View {
        FrameDetailToolbar(frame: $placeholderFrame, shouldProcess: .constant(true), store: testStore, showProcessedFrame: .constant(false), isProcessing: .constant(false), processingStatus: .constant("Loading"), timingStatus: .constant("Timing Data"), modelURL: .constant(nil))
    }
}
