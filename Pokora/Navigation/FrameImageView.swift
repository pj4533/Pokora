//
//  FrameImageView.swift
//  Pokora
//
//  Created by PJ Gray on 4/20/23.
//

import SwiftUI

struct FrameImageView: View {
    var imageUrl: URL?
    var emptyStateString: String
    
    var body: some View {
        ZStack {
            Color.clear
                .frame(width: 512, height: 512)
            if let url = imageUrl, let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 512, height: 512)
            } else {
                VStack {
                    Image(systemName: "video.slash.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.primary)
                    Spacer()
                        .frame(height: 50)
                    Text(emptyStateString)
                }
            }
        }
    }
}

struct FrameImageView_Previews: PreviewProvider {
    static var previews: some View {
        FrameImageView(imageUrl: nil, emptyStateString: "No frame loaded")
    }
}
