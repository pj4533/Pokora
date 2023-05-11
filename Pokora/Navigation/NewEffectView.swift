//
//  NewEffectView.swift
//  Pokora
//
//  Created by PJ Gray on 5/2/23.
//

import SwiftUI

struct NewEffectView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: VideoStore
    @Binding var selectedEffect: UUID?
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
        .frame(maxHeight: 220.0)
        .navigationTitle(selectedEffect == nil ? "Add Effect" : "Edit Effect")
        .toolbar {
            ToolbarItemGroup {
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    if let id = selectedEffect {
                        if let index = store.project.effects.firstIndex(where: { $0.id == id }) {
                            store.project.effects[index].prompt = prompt
                            store.project.effects[index].startStrength = startStrength
                            store.project.effects[index].endStrength = endStrength
                            store.project.effects[index].seed = seed
                        }
                    } else {
                        store.project.addEffect(startFrame: store.currentFrameNumber ?? 0, prompt: prompt, startStrength: startStrength, endStrength: endStrength, seed: seed)
                    }
                    dismiss()
                }
            }
        }
        .onAppear {
            if let id = selectedEffect, let effect = store.project.effects.first(where: { $0.id == id }) {
                prompt = effect.prompt
                startStrength = effect.startStrength
                endStrength = effect.endStrength
                seed = effect.seed
            }
        }
    }
}

struct NewEffectView_Previews: PreviewProvider {
    static var previews: some View {
        NewEffectView(selectedEffect: .constant(nil))
            .environmentObject(VideoStore())
    }
}
