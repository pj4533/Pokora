//
//  Sidebar.swift
//  Pokora
//
//  Created by PJ Gray on 2/23/23.
//

import SwiftUI

struct Sidebar: View {
    @State private var video: Video?
    @State private var selectedFrame: Frame?
    
    init(video: Video?) {
        self.video = video
    }
    
    var body: some View {
        VStack {
            if let frames = video?.frames, !frames.isEmpty {
                List(video?.frames ?? [], id: \.self, selection: $selectedFrame) { frame in
                    NavigationLink {
                        FrameDetail(frame: frame)
                    } label: {
                        Label("Frame #\(frame.index)", systemImage: "video.square.fill")
                        if frame.outputUrl == nil {
                            Image(systemName: "square")
                        } else {
                            Image(systemName: "checkmark.square.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            } else {
                Button("Select File") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    if panel.runModal() == .OK, let url = panel.url {
                        Store.loadVideo(url: url) { loadedVideo in
                            video = loadedVideo
                            selectedFrame = video?.frames.first
                        }
                    }
                }
                Text("Please select a video above to load frames.")
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top)
            }
        }
    }
}

struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar(video: testvideo)
    }
}

