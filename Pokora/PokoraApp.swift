//
//  PokoraApp.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

@main
struct PokoraApp: App {
    @ObservedObject var store: VideoStore = VideoStore()
    var body: some Scene {
        DocumentGroup(newDocument: { store }) { configuration in
            ContentView()
        }
        Settings {
            SettingsView()
                .environmentObject(store)
        }
    }
}
