//
//  ContentView.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var store: VideoStore
    @State var selectedEffect: UUID?
    @State private var showNewEffectSheet = false
    
    var body: some View {
        NavigationSplitView {
            if store.video.url != nil {
                VStack {
                    if store.effects.isEmpty {
                        Button("Add Effect") {
                            showNewEffectSheet = true
                        }
                    } else {
                        List($store.effects, selection: $selectedEffect) {
                            EffectCell(effect: $0)
                        }
                    }
                }
                .navigationTitle("Effects")
            } else {
                VStack {
                    Button("Select File") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        if panel.runModal() == .OK, let url = panel.url {
                            Task {
                                do {
                                    try await store.loadVideo(url: url)
                                } catch let error {
                                    print("ERROR LOADING VIDEO: \(error)")
                                }
                            }
                        }
                    }
                    Text("Please select a video above")
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                }
            }
        } detail: {
            if store.player != nil {
                VideoPlayerView(store: store, selectedEffect: store.effects.first(where: {$0.id == selectedEffect}))
                .toolbar {
                    ToolbarItem {
                        Button("Render") {
                            Task {
                                await store.extractFrames()
                            }
//                            shouldProcess = true
//                            processingStatus = "Initializing Pipeline..."
//                            isProcessing = true
//                            DispatchQueue.global().async {
//                                for (index, frame) in store.video.frames.enumerated() {
//                                    do {
//                                        try process(frame: frame, atIndex: index)
//                                        DispatchQueue.main.async {
//                                            showProcessedFrame = true
//                                        }
//                                    } catch let error {
//                                        DispatchQueue.main.async {
//                                            showProcessedFrame = true
//                                            isProcessing = false
//                                            self.showErrorDialog(with: error)
//                                        }
//                                    }
//                                    if !shouldProcess { break }
//                                    selectedFrames = Set([frame.id])
//                                }
//                                isProcessing = false
//                            }
                        }
                        .disabled(store.effects.isEmpty)
                    }
                    ToolbarItem {
                        Button {
                            showNewEffectSheet = true
                        } label: {
                            Label("Add Effect", systemImage: "plus")
                        }
                        .keyboardShortcut("i", modifiers: [.command])
                        .disabled(store.hasEffect(atFrameIndex: store.currentFrameNumber ?? 0))
                    }
                }

            }
        }
        .onChange(of: store.currentFrameNumber) { newValue in
            selectedEffect = nil
        }
        .sheet(isPresented: $showNewEffectSheet) {
            NewEffectView(store: store)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: testStore)
    }
}
