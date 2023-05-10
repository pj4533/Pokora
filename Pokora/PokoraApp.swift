//
//  PokoraApp.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

@main
struct PokoraApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: { VideoStore() }) { configuration in
            ContentView()
        }
    }
}
