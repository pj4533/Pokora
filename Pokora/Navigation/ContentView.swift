//
//  ContentView.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var store: VideoStore

    @State var selectedEffect: UUID?
    @State private var showNewEffectSheet = false
    @AppStorage("modelURL") private var modelURL: URL?

    var body: some View {
        ZStack {
            NavigationSplitView {
                if store.project.video.url != nil {
                    VStack {
                        if store.project.effects.isEmpty {
                            Button("Add Effect") {
                                showNewEffectSheet = true
                            }
                        } else {
                            List($store.project.effects, selection: $selectedEffect) {
                                EffectCell(effect: $0, store: store)
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
                    VideoPlayerView(store: store, modelURL: $modelURL, selectedEffect: store.project.effects.first(where: {$0.id == selectedEffect}))
                    .toolbar {
                        ToolbarItem {
                            Button("Render") {
                                Task {
                                    await store.extractFrames()
                                    await store.processFrames(modelURL: modelURL)
                                }
                            }
                            .disabled(store.project.effects.isEmpty)
                        }
                        ToolbarItem {
                            Button("Export") {
                                let panel = NSSavePanel()
                                panel.nameFieldStringValue = "exported.mov"
                                panel.canCreateDirectories = true
                                panel.prompt = "Export"

                                panel.begin { response in
                                    if response == .OK, let outputUrl = panel.url {
                                        Task {
                                            do {
                                                if let url = store.project.video.url, let pngs = store.project.video.frames?.map({ $0.processedUrl ?? $0.url }) as? [URL] {
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
                            .disabled((store.project.video.frames?.compactMap({ $0.processedUrl }).count ?? 0) == 0)
                        }
                        ToolbarItem {
                            Button {
                                showNewEffectSheet = true
                            } label: {
                                Label("Add Effect", systemImage: "plus")
                            }
                            .keyboardShortcut("i", modifiers: [.command])
                            .disabled(store.project.hasEffect(atFrameIndex: store.currentFrameNumber ?? 0))
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

            if store.isExtracting {
                ProcessingView(statusText: .constant("Extracting frames..."), additionalStatusText: .constant(""), shouldProcess: .constant(true), showCancel: false)
            }
            if store.isProcessing {
                ProcessingView(statusText: $store.processingStatus, additionalStatusText: $store.timingStatus, shouldProcess: $store.shouldProcess)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: VideoStore(project: PokoraProject(video: Video())))
    }
}
