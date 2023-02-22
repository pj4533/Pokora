//
//  ContentView.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

struct ContentView: View {
    @SceneStorage("selection") var selection: Frame.ID?
    
    var body: some View {
        NavigationView {
            Sidebar(selection: $selection)
            FrameDetail(frameId: $selection)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Store())
    }
}

struct Sidebar: View {
    @EnvironmentObject var store: Store
    @Binding var selection: Frame.ID?
    
    var body: some View {
        Button("Select File") {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            if panel.runModal() == .OK {
                store.movieFileUrl = panel.url
                print("\(store.movieFileUrl?.absoluteString ?? "")")
                store.readFrames()
            }
        }
        List(selection: $selection) {
            ForEach(store.frames) { frame in
                Label("Frame #\(frame.id)", systemImage: "video.square.fill")
            }
        }
    }
}
