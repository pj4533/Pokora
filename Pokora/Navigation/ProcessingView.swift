//
//  ProcessingView.swift
//  Pokora
//
//  Created by PJ Gray on 5/3/23.
//

import SwiftUI

struct ProcessingView: View {
    @EnvironmentObject var store: VideoStore
    @Binding var statusText: String
    @Binding var additionalStatusText: String
    @Binding var shouldProcess: Bool
    @Binding var showThumbnails: Bool
    var showCancel: Bool = true
    var body: some View {
        VStack {
            Text("🧠🧠🧠🧠🧠")
                .font(.largeTitle.bold())
            Text(statusText)
                .foregroundStyle(.secondary)
                .font(.title2.bold())
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Spacer()
                .frame(height: 10.0)
            Text(additionalStatusText)
                .foregroundStyle(.tertiary)
                .font(.title3)
            if showThumbnails {
                ThumbnailScrollView(imageUrls: store.project.video.frames?.compactMap { ($0.processedUrl, $0.index) }.sorted(by: { $0.1 > $1.1 }).compactMap { $0.0 } ?? [])
                    .padding()
            }
            if showCancel {
                Button("Cancel") {
                    shouldProcess = false
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16.0))
    }
}

struct ProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingView(statusText: .constant("Loading"), additionalStatusText: .constant("Test"), shouldProcess: .constant(true), showThumbnails: .constant(false))
    }
}
