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
    @State private var cgImage: CGImage? = nil
    @State private var effectType: Effect.EffectType = .direct
    @Binding var modelURL: URL?

    var body: some View {
        ZStack {
            HStack {
                Form {
                    Picker("Effect Type", selection: $effectType) {
                        ForEach(Effect.EffectType.allCases, id: \.self) { effectType in
                            Text(effectType.rawValue.capitalized).tag(effectType)
                        }
                    }
                    TextField("Prompt", text: $prompt)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Stepper("Start Strength", value: $startStrength, step: 0.1, format: .number)
                    Stepper("End Strength", value: $endStrength, step: 0.1, format: .number)
                    if effectType == .direct {
                        HStack {
                            TextField("Seed", value: $seed, format: .number.grouping(.never))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button {
                                seed = UInt32.random(in: 0...UInt32.max)
                            } label: {
                                Label("", systemImage: "die.face.3.fill")
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
                .formStyle(.grouped)
                VStack {
                    if let cgImage = cgImage {
                        Image(nsImage: NSImage(cgImage: cgImage, size: NSSize(width: 512.0, height: 512.0)))
                            .frame(minWidth: 512.0, minHeight: 512.0)
                            .cornerRadius(12.0)
                    } else {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 50))
                            .frame(minWidth: 512.0, minHeight: 512.0)
                            .cornerRadius(12.0)
                    }
                    Button("Preview") {
                        Task {
                            if (store.project.video.frames?.count ?? 0) == 0 {
                                await store.extractFrames()
                            }
                            // preview needs to take into account generative vs direct
                            if let id = selectedEffect {
                                if let index = store.project.effects.firstIndex(where: { $0.id == id }), let url = store.project.video.frames?[ store.project.effects[index].startFrame ].url {
                                    cgImage = try await store.processPreview(imageUrl: url, prompt: prompt, strength: startStrength, seed: seed, modelURL: modelURL)
                                }
                            } else {
                                if let url = store.project.video.frames?[ store.currentFrameNumber ?? 0 ].url {
                                    cgImage = try await store.processPreview(imageUrl: url, prompt: prompt, strength: startStrength, seed: seed, modelURL: modelURL)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
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
                                store.project.effects[index].effectType = effectType
                            }
                        } else {
                            store.project.addEffect(effectType: effectType, startFrame: store.currentFrameNumber ?? 0, prompt: prompt, startStrength: startStrength, endStrength: endStrength, seed: seed)
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
                    effectType = effect.effectType ?? .direct
                }
            }
            if store.isExtracting {
                ProcessingView(statusText: .constant("Extracting frames..."), additionalStatusText: $store.timingStatus, shouldProcess: .constant(true), showThumbnails: .constant(false), showCancel: false)
            }
            if store.isProcessing {
                ProcessingView(statusText: $store.processingStatus, additionalStatusText: $store.timingStatus, shouldProcess: $store.shouldProcess, showThumbnails: .constant(false))
            }
        }
    }
}

struct NewEffectView_Previews: PreviewProvider {
    static var previews: some View {
        NewEffectView(selectedEffect: .constant(nil), modelURL: .constant(nil))
            .environmentObject(VideoStore())
    }
}
