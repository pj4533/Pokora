//
//  ContentView.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var store: VideoStore

    var body: some View {
        NavigationSplitView {
            if store.video.url != nil {
                VStack {
                    if store.effects.isEmpty {
                        Button("Add Effect") {
                            Task {
                                await store.addEffect()
                            }
                        }
                    } else {
                        List {
                            ForEach(store.effects) { effect in
                                Text("Start: \(effect.startFrame) End: \(effect.endFrame)")
                            }
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
                                await store.loadVideo(url: url)
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
                VideoPlayerView(store: store)
                .toolbar {
                    ToolbarItem {
                        Button {
                            Task {
                                await store.addEffect()
                            }
                        } label: {
                            Label("Add Effect", systemImage: "plus")
                        }
                        .keyboardShortcut("i", modifiers: [.command])
                    }
                }

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
