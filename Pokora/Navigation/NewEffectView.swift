//
//  NewEffectView.swift
//  Pokora
//
//  Created by PJ Gray on 5/2/23.
//

import SwiftUI

struct NewEffectView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: VideoStore
    @State private var prompt = "A cyberpunk cityscape"
    @State private var strength: Float = 0.2
    @State private var seed = globalSeed
    var body: some View {
        Form {
            TextField("Prompt", text: $prompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Stepper("Strength", value: $strength, step: 0.1, format: .number)
            TextField("Seed", value: $seed, format: .number.grouping(.never))
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .formStyle(.grouped)
        .frame(maxHeight: 170.0)
        .navigationTitle("Add Effect")
        .toolbar {
            ToolbarItem {
                Button("Save") {
                    Task {
                        await store.addEffect(prompt: prompt, strength: strength, seed: seed)
                    }
                    dismiss()
                }
            }
        }
    }
}

struct NewEffectView_Previews: PreviewProvider {
    static var previews: some View {
        NewEffectView(store: emptyStore)
    }
}
