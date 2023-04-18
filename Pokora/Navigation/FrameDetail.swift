//
//  FrameDetail.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

struct FrameDetail: View {
    var frame: Frame?

    var body: some View {
        HStack {
            VStack {
                if let url = frame?.inputUrl, let image = NSImage(contentsOf: url) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Text("Error loading image")
                }
            }
            VStack {
                if let url = frame?.outputUrl, let image = NSImage(contentsOf: url) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    if let url = frame?.inputUrl {
                        StableDiffusionStore.process(imageUrl: url)
                    } else {
                        Text("Error input loading image")
                    }
                }
            }
        }
    }
}

struct FrameDetail_Previews: PreviewProvider {
    static var previews: some View {
        FrameDetail(frame: Frame.placeholder)
    }
}
