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
    @State private var startStrength: Float = 0.2
    @State private var endStrength: Float = 0.2
    @State private var seed = globalSeed
    var body: some View {
        Form {
            TextField("Prompt", text: $prompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Stepper("Start Strength", value: $startStrength, step: 0.1, format: .number)
            Stepper("End Strength", value: $endStrength, step: 0.1, format: .number)
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
                        await store.addEffect(prompt: prompt, startStrength: startStrength, endStrength: endStrength, seed: seed)
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
