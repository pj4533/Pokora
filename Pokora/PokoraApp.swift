//
//  PokoraApp.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

@main
struct PokoraApp: App {
    @StateObject private var store = VideoStore(video: Video())

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(store: store)
                if store.isExtracting {
                    ProcessingView(statusText: .constant("Extracting frames..."), additionalStatusText: .constant(""), shouldProcess: .constant(true), showCancel: false)
                }
            }
        }
    }
}
