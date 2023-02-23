//
//  ContentView.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

struct ContentView: View {
    @State var video: Video?

    var body: some View {
        NavigationSplitView {
            Sidebar(video: video)
        } detail: {
            FrameDetail(frame: video?.frames.first)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(video: testvideo)
    }
}
