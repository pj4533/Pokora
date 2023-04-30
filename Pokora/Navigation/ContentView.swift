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
        } detail: {
            if let url = store.video.url {
                VideoPlayerView(videoPlayer: VideoPlayerModel(url: url))
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
