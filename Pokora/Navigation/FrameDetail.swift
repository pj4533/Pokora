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
    @State private var shouldProcess = true
    @State private var showProcessed = false
    @State private var isProcessing = false
    @State private var processingStatus = "Loading..."
    @State private var timingStatus = ""
    
    var body: some View {
        let url = showProcessed ? frame.processed.url ?? frame.url : frame.url
        ZStack {
            VStack {
                FrameImageView(imageUrl: url, emptyStateString: "No frame loaded")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Form {
                    Section {
                        TextField("Prompt", text: $frame.processed.prompt)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Stepper("Strength", value: $frame.processed.strength, step: 0.1, format: .number)
                        TextField("Seed", value: $frame.processed.seed, format: .number.grouping(.never))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .formStyle(.grouped)
                .frame(maxHeight: 160.0)
            }
            if isProcessing {
                ProcessingView(statusText: $processingStatus, additionalStatusText: $timingStatus, shouldProcess: $shouldProcess)
            }
        }
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                FrameDetailToolbar(frame: $frame,
                                   shouldProcess: $shouldProcess,
                                   store: store,
                                   showProcessedFrame: $showProcessed,
                                   isProcessing: $isProcessing,
                                   processingStatus: $processingStatus,
                                   timingStatus: $timingStatus)
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
