//
//  VideoPlayerView.swift
//  Pokora
//
//  Created by PJ Gray on 4/30/23.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @ObservedObject var store: VideoStore
    @Binding var modelURL: URL?
    
    var selectedEffect: Effect?

    var body: some View {
        VStack {
            VideoPlayer(player: store.player)
                .cornerRadius(10)
                .padding()
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
            }
            .formStyle(.grouped)
            .frame(maxHeight: 130.0)
        }
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerView(store: emptyStore, modelURL: .constant(nil), selectedEffect: nil)
    }
}
