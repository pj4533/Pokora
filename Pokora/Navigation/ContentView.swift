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
        NavigationView {
            // TODO: There is some way to make this placeholder work automatically
            if let frames = store.video?.frames, !frames.isEmpty {
                List {
                    ForEach(frames) { frame in
                        FrameCell(frameIndex: frame.index, store: store)
                    }
                }
            } else {
                VStack {
                    Button("Select File") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        if panel.runModal() == .OK, let url = panel.url {
                            store.loadVideo(url: url)
                        }
                    }
                    Text("Please select a video above to load frames.")
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: testStore)
        ContentView(store: VideoStore())
    }
}
