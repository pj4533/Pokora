//
//  Sidebar.swift
//  Pokora
//
//  Created by PJ Gray on 2/23/23.
//

import SwiftUI

struct Sidebar: View {
    @State private var video: Video?
    
    init(video: Video?) {
        self.video = video
    }
    
    var body: some View {
        VStack {
            Button("Select File") {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                if panel.runModal() == .OK, let url = panel.url {
                    Store.loadVideo(url: url) { loadedVideo in
                        video = loadedVideo
                    }
                }
            }
            List {
                ForEach(video?.frames ?? []) { frame in
                    NavigationLink {
                        FrameDetail(frame: frame)
                    } label: {
                        Label("Frame #\(frame.index)", systemImage: "video.square.fill")
                    }
                }
            }
        }
    }
}

struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar(video: testvideo)
    }
}

