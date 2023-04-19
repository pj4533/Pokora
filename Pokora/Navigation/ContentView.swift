//
//  ContentView.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

struct ContentView: View {
    @State private var video: Video?

    init(video: Video? = nil) {
        self.video = video
    }
    
    var body: some View {
        NavigationSplitView {
            Sidebar(video: video)
        } detail: {
            FrameDetail(frame: Frame.placeholder)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(video: testvideo)
    }
}
