//
//  ContentView.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: VideoStore
    @State var selectedEffect: UUID?
    @State private var showNewEffectSheet = false
    @AppStorage("modelURL") private var modelURL: URL?

    var body: some View {
        ZStack {
            NavigationSplitView {
                if store.project.video.bookmarkData != nil {
                    VStack {
                        if store.project.effects.isEmpty {
                            Button("Add Effect") {
                                showNewEffectSheet = true
                            }
                        } else {
                            List($store.project.effects) { effect in
                                EffectCell(effect: effect)
                                    .contentShape(Rectangle())
                                    .onTapGesture(count: 2) {
                                        selectedEffect = effect.id
                                        showNewEffectSheet = true
                                    }
                            }
                        }
                    }
                    .navigationTitle("Effects")
                    .frame(minWidth: 320.0)
                    .onAppear {
                        if store.player == nil {
                            Task {
                                do {
                                    try await store.loadVideo()
                                } catch let error {
                                    print("ERROR LOADING VIDEO: \(error)")
                                }
                            }
                        }
                    }
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
                    VideoPlayerView(modelURL: $modelURL)
                    .toolbar {
                        ToolbarItem {
                            Button("Render") {
                                Task {
                                    if (store.project.video.frames?.count ?? 0) == 0 {
                                        await store.extractFrames()
                                    }
                                    await store.processFrames(modelURL: modelURL)
                                }
                            }
                            .disabled(store.project.effects.isEmpty)
                        }
                        ToolbarItem {
                            Menu("Export") {
                                Button("Export without Uprez") {
                                    self.export(shouldUprez: false)
                                }
                            } primaryAction: {
                                self.export(shouldUprez: true)
                            }
                            .disabled((store.project.video.frames?.compactMap({ $0.processedUrl }).count ?? 0) == 0)
                        }
                        ToolbarItem {
                            Button {
                                selectedEffect = nil
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
            .sheet(isPresented: $showNewEffectSheet) {
                NewEffectView(selectedEffect: $selectedEffect, modelURL: $modelURL)
            }

            if store.isUprezzing {
                ProcessingView(statusText: .constant("Uprezzing..."), additionalStatusText: $store.timingStatus, shouldProcess: .constant(true), showThumbnails: .constant(false), showCancel: false)
            }
            if store.isExporting {
                ProcessingView(statusText: .constant("Exporting..."), additionalStatusText: $store.timingStatus, shouldProcess: .constant(true), showThumbnails: .constant(false), showCancel: false)
            }
            if store.isExtracting {
                ProcessingView(statusText: .constant("Extracting frames..."), additionalStatusText: $store.timingStatus, shouldProcess: .constant(true), showThumbnails: .constant(false), showCancel: false)
            }
            if store.isProcessing {
                ProcessingView(statusText: $store.processingStatus, additionalStatusText: $store.timingStatus, shouldProcess: $store.shouldProcess, showThumbnails: $store.showThumbnails, showCancel: true)
            }
        }
    }
    
    func export(shouldUprez: Bool) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "exported.mov"
        panel.canCreateDirectories = true
        panel.prompt = "Export"

        panel.begin { response in
            if response == .OK, let outputUrl = panel.url {
                Task {
                    do {
                        if let bookmarkData = store.project.video.bookmarkData {
                            var isStale = false
                            let bookmarkedURL = try URL(resolvingBookmarkData: bookmarkData,
                                                        options: .withSecurityScope,
                                                        relativeTo: nil,
                                                        bookmarkDataIsStale: &isStale)
                            
                            if isStale {
                                // The bookmarked data is stale, handle this error appropriately in your app
                            } else {
                                if bookmarkedURL.startAccessingSecurityScopedResource() {
                                    // You have access to the file, you can perform your file operations here
                                    if let pngs = store.project.video.frames?.map({ $0.processedUrl ?? $0.url }) as? [URL] {
                                        if shouldUprez {
                                            try await store.uprez(pngURLs: pngs)
                                        }
                                        let outputUrl = try await store.exportVideoWithPNGs(videoURL: bookmarkedURL, pngURLs: pngs, outputURL: outputUrl)
                                        print("OUTPUT: \(outputUrl)")
                                    }

                                    // Make sure to stop accessing the resource when you're done
                                    bookmarkedURL.stopAccessingSecurityScopedResource()
                                }
                            }
                        }
                    } catch let error {
                        print("ERROR EXPORTING: \(error)")
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(VideoStore())
    }
}
