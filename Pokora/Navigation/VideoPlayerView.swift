//
//  VideoPlayerView.swift
//  Pokora
//
//  Created by PJ Gray on 4/30/23.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @StateObject var videoPlayer: VideoPlayerModel
    
    var body: some View {
        VStack {
            VideoPlayer(player: videoPlayer.player)
                .cornerRadius(10)
                .padding()
            
            Button("Get Frame Number") {
                Task {
                    if let frameNumber = await videoPlayer.currentFrameNumber() {
                        print("Current frame number: \(frameNumber)")
                    } else {
                        print("Error getting frame number.")
                    }
                }
            }
        }
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        // I dunno, this preview always crashes?
        VideoPlayerView(videoPlayer: VideoPlayerModel(url: Bundle.main.url(forResource: "whut", withExtension: "mp4")!))
    }
}
