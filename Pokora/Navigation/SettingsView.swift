//
//  SettingsView.swift
//  Pokora
//
//  Created by PJ Gray on 5/18/23.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: VideoStore
    @State private var showClearCacheAlert = false
    @State private var isDeleting = false
    
    var body: some View {
        ZStack {
            Form {
                Button("Clear Cache") {
                    showClearCacheAlert = true
                }
                .alert(isPresented: $showClearCacheAlert) {
                    Alert(
                        title: Text("Warning"),
                        message: Text("Should clear cache?"),
                        primaryButton: .destructive(Text("Delete")) {
                            Task {
                                await MainActor.run {
                                    isDeleting = true
                                }
                                let fileManager = FileManager.default
                                let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
                                
                                do {
                                    let contents = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil, options: [])
                                    for item in contents {
                                        try fileManager.removeItem(at: item)
                                    }
                                    await MainActor.run {
                                        isDeleting = false
                                    }
                                } catch {
                                    print("Failed to clear cache: \(error)")
                                    await MainActor.run {
                                        isDeleting = false
                                    }
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            .frame(width: 400, height: 200, alignment: .top)
            .padding()
            if isDeleting {
                ProcessingView(statusText: .constant("Removing Cache..."), additionalStatusText: .constant(""), shouldProcess: .constant(true), showThumbnails: .constant(false), showCancel: false)
            }
        }
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
