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
    var selectedEffect: Effect?
    
    var body: some View {
        VStack {
            VideoPlayer(player: store.player)
                .cornerRadius(10)
                .padding()
            if let promptValue = selectedEffect?.prompt, let seedValue = selectedEffect?.seed, let strengthValue = selectedEffect?.strength {
                Form {
                    LabeledContent("Prompt", value: promptValue)
                    LabeledContent("Strength", value: String(strengthValue))
                    LabeledContent("Seed", value: String(seedValue))
                }
                .formStyle(.grouped)
                .frame(maxHeight: 170.0)
            } else {
                Text("(no effect selected)")
                    .frame(maxHeight: 170.0)
            }
        }
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerView(store: emptyStore, selectedEffect: nil)
    }
}
