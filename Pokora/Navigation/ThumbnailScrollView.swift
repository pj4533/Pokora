//
//  ThumbnailScrollView.swift
//  Pokora
//
//  Created by PJ Gray on 5/17/23.
//

import SwiftUI

struct ThumbnailScrollView: View {
    let imageUrls: [URL]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(imageUrls, id: \.self) { url in
                    ThumbnailView(imageURL: url)
                }
            }
            .padding()
        }
        .frame(width: 400.0, height: 100.0)
    }
}


struct ThumbnailScrollView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailScrollView(imageUrls: [])
    }
}
