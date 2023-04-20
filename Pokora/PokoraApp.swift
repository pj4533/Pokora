//
//  PokoraApp.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

@main
struct PokoraApp: App {
    @StateObject private var store = VideoStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}
