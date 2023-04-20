//
//  FrameCell.swift
//  Pokora
//
//  Created by PJ Gray on 4/20/23.
//

import SwiftUI

struct FrameCell: View {
    var frameIndex: Int
    @ObservedObject var store: VideoStore

    var body: some View {
        NavigationLink {
            FrameDetail(frameIndex: frameIndex, store: store)
        } label: {
            Label("Frame #\(frameIndex)", systemImage: "video.square.fill")
            if store.video?.frames[frameIndex-1].processed == nil {
                Image(systemName: "square")
            } else {
                Image(systemName: "checkmark.square.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

struct FrameCell_Previews: PreviewProvider {
    static var previews: some View {
        FrameCell(frameIndex: 1, store: VideoStore())
    }
}
