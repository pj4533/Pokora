//
//  ContentView.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var store: VideoStore
    @State private var selectedFrames = Set<UUID>()

    var body: some View {
        NavigationSplitView {
            if !store.video.frames.isEmpty {
                List($store.video.frames, selection: $selectedFrames) {
                    FrameCell(frame: $0, store: store, selectedFrames: $selectedFrames)
                }
                .onAppear() {
                    if let frameId = $store.video.frames.first?.id {
                        selectedFrames.insert(frameId)
                    }
                }
                Text("\(selectedFrames.count) selections")
            } else {
                VStack {
                    Button("Select File") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        if panel.runModal() == .OK, let url = panel.url {
                            Task {
                                await store.loadVideo(url: url)
                            }
                        }
                    }
                    Text("Please select a video above to load frames.")
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                }
            }
        } detail: {
            if let frame = $store.video.frames.first {
                FrameDetail(frame: frame, selectedFrames: $selectedFrames, store: store)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: testStore)
        ContentView(store: VideoStore(video: Video()))
    }
}
