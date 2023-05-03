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
        }
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerView(store: emptyStore, selectedEffect: nil)
    }
}
