//
//  ThumbnailView.swift
//  Pokora
//
//  Created by PJ Gray on 5/17/23.
//

import SwiftUI

struct ThumbnailView: View {
    @State private var showFullScreen = false
    let imageURL: URL
    
    var body: some View {
        Button(action: { self.showFullScreen.toggle() }) {
            VStack {
                Image(nsImage: NSImage(contentsOf: imageURL) ?? NSImage())
                    .resizable()
                    .cornerRadius(12.0)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .sheet(isPresented: $showFullScreen) {
                        Image(nsImage: NSImage(contentsOf: imageURL) ?? NSImage())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                Text(imageURL.lastPathComponent.replacingOccurrences(of: "out", with: "").replacingOccurrences(of: "_processed.png", with: ""))
                    .font(.footnote)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailView(imageURL: URL(fileURLWithPath: ""))
    }
}
