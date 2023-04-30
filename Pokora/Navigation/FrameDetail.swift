//
//  FrameDetail.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

struct FrameDetail: View {
    @Binding var frame: Frame
    @Binding var selectedFrames: Set<UUID>

    @ObservedObject var store: VideoStore
    @State private var shouldProcess = true
    @State private var showProcessed = false
    @State private var isProcessing = false
    @State private var processingStatus = "Loading..."
    @State private var timingStatus = ""

    @AppStorage("modelURL") private var modelURL: URL?

    var body: some View {
        let url = showProcessed ? frame.processed.url ?? frame.url : frame.url
        ZStack {
            VStack {
                FrameImageView(imageUrl: url, emptyStateString: "No frame loaded")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Form {
                    Section("Model") {
                        Button("\(modelURL?.lastPathComponent ?? "<choose model>")") {
                            let panel = NSOpenPanel()
                            panel.allowsMultipleSelection = false
                            panel.canChooseDirectories = true
                            panel.canChooseFiles = false
                            if panel.runModal() == .OK, let url = panel.url {
                                modelURL = url
                                store.pipeline = nil
                            }
                        }
                    }

                    // need to refactor this, the way it works is like the garden demo app, but this is way
                    // too complicated and i don't like how i pass in the 'frame' and a selection. it should be one
                    // concept
                    Section("Frame") {
                        TextField("Prompt", text: Binding(get: {
                            let prompts = Set(selectedFrames.map({ frameId in
                                store.video.frames.first(where: { $0.id == frameId })?.processed.prompt ?? ""
                            }))
                            return prompts.count == 1 ? prompts.first! : "<multiple selected>"
                        }, set: { newValue in
                            for (index, frame) in $store.video.frames.enumerated() {
                                if selectedFrames.contains(frame.id) {
                                    store.video.frames[index].processed.prompt = newValue
                                }
                            }
                        }))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        Stepper("Strength", value: Binding(get: {
                            let values = Set(selectedFrames.map({ frameId in
                                store.video.frames.first(where: { $0.id == frameId })?.processed.strength ?? 0.0
                            }))
                            return Double(values.count == 1 ? values.first! : 0.0)
                        }, set: { newValue in
                            for (index, frame) in $store.video.frames.enumerated() {
                                if selectedFrames.contains(frame.id) {
                                    store.video.frames[index].processed.strength = Float(newValue)
                                }
                            }
                        }), step: 0.1, format: .number)
                        TextField("Seed", value: Binding(get: {
                            let values = Set(selectedFrames.map({ frameId in
                                store.video.frames.first(where: { $0.id == frameId })?.processed.seed ?? 0
                            }))
                            return Decimal(values.count == 1 ? values.first! : 0)
                        }, set: { newValue in
                            for (index, frame) in $store.video.frames.enumerated() {
                                if selectedFrames.contains(frame.id) {
                                    store.video.frames[index].processed.seed = UInt32(newValue.formatted()) ?? 0
                                }
                            }
                        }), format: .number.grouping(.never))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .formStyle(.grouped)
                .frame(maxHeight: 300.0)
            }
            if isProcessing {
                ProcessingView(statusText: $processingStatus, additionalStatusText: $timingStatus, shouldProcess: $shouldProcess)
            }
        }
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                FrameDetailToolbar(frame: $frame,
                                   selectedFrames: $selectedFrames,
                                   shouldProcess: $shouldProcess,
                                   store: store,
                                   showProcessedFrame: $showProcessed,
                                   isProcessing: $isProcessing,
                                   processingStatus: $processingStatus,
                                   timingStatus: $timingStatus,
                                   modelURL: $modelURL)
            }
        }
    }
}

struct FrameDetail_Previews: PreviewProvider {
    @State static private var placeholderFrame = Frame.placeholder

    static var previews: some View {
        FrameDetail(frame: $placeholderFrame, selectedFrames: .constant([]), store: VideoStore(video: Video()))
    }
}
