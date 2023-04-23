//
//  FrameCell.swift
//  Pokora
//
//  Created by PJ Gray on 4/20/23.
//

import SwiftUI

struct FrameCell: View {
    @Binding var frame: Frame
    @ObservedObject var store: VideoStore

    var body: some View {
        NavigationLink {
            FrameDetail(frame: $frame, store: store)
        } label: {
            Label("Frame #\(frame.index)", systemImage: "video.square.fill")
            if frame.processed.url == nil {
                Image(systemName: "square")
            } else {
                Image(systemName: "checkmark.square.fill")
                    .foregroundColor(.green)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct FrameCell_Previews: PreviewProvider {
    @State static private var placeholderFrame = Frame.placeholder

    static var previews: some View {
        FrameCell(frame: $placeholderFrame, store: VideoStore(video: Video()))
    }
}
