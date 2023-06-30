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
    @State private var stepCount: Double = 30
    @State private var cgImage: CGImage? = nil
    @State private var effectType: Effect.EffectType = .direct
    @State private var rotateAngle: Float = 0.4
    @State private var rotateDirection: Effect.RotateDirection = .clockwise
    @State private var renderDirection: Effect.RenderDirection = .forward
    @State private var zoomScale: Float = 1.005
    @State private var startFrame: Int?
    @State private var endFrame: Int?
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
                    Stepper("Step Count", value: $stepCount, step: 1.0, format: .number)
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
                    } else {
                        Picker("Render Direction", selection: $renderDirection) {
                            Text("Forward").tag(Effect.RenderDirection.forward)
                            Text("Reverse").tag(Effect.RenderDirection.reverse)
                        }
                        Picker("Rotate Direction", selection: $rotateDirection) {
                            Text("Clockwise").tag(Effect.RotateDirection.clockwise)
                            Text("Counter Clockwise").tag(Effect.RotateDirection.counterclockwise)
                        }
                        Stepper("Rotate Angle", value: $rotateAngle, step: 0.1, format: .number)
                        Stepper("Zoom Scale", value: $zoomScale, step: 0.001, format: .number)
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
                            
                            var frameIndex = startFrame ?? 0
                            var url: URL?
                            if effectType == .direct {
                                url = store.project.video.frames?[ frameIndex ].url
                            } else if effectType == .generative {
                                if renderDirection == .forward {
                                    if frameIndex == 0 {
                                        url = store.project.video.frames?[frameIndex].url
                                    } else if let previousProcessedUrl = store.project.video.frames?[frameIndex-1].processedUrl {
                                        url = previousProcessedUrl
                                    } else if let previousUrl = store.project.video.frames?[frameIndex-1].url {
                                        url = previousUrl
                                    } else {
                                        print("Could not find previous frame for generative processing at index \(frameIndex - 1)...")
                                    }
                                } else {
                                    frameIndex = endFrame ?? 0
                                    if frameIndex == store.project.video.lastFrameIndex ?? 0 {
                                        url = store.project.video.frames?[frameIndex].url
                                    } else if let nextProcessedUrl = store.project.video.frames?[frameIndex+1].processedUrl {
                                        url = nextProcessedUrl
                                    } else if let nextUrl = store.project.video.frames?[frameIndex+1].url {
                                        url = nextUrl
                                    } else {
                                        print("Could not find next frame for generative processing at index \(frameIndex + 1)...")
                                    }
                                }
                            }
                            if let url = url {
                                do {
                                    cgImage = try await store.processPreview(imageUrl: url, prompt: prompt, strength: startStrength, seed: seed, stepCount: Int(stepCount), rotateDirection: rotateDirection, rotateAngle: rotateAngle, zoomScale: zoomScale, modelURL: modelURL)
                                } catch let error {
                                    print("ERROR: \(error.localizedDescription)")
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
                                store.project.effects[index].stepCount = Int(stepCount)
                                store.project.effects[index].effectType = effectType
                                store.project.effects[index].rotateDirection = effectType == .direct ? nil : rotateDirection
                                store.project.effects[index].renderDirection = renderDirection
                                store.project.effects[index].rotateAngle = effectType == .direct ? nil : rotateAngle
                                store.project.effects[index].zoomScale = effectType == .direct ? nil : zoomScale
                            }
                        } else {
                            store.project.addEffect(effectType: effectType, startFrame: store.currentFrameNumber ?? 0, prompt: prompt, startStrength: startStrength, endStrength: endStrength, seed: seed, stepCount: Int(stepCount), rotateDirection: effectType == .direct ? nil : rotateDirection, rotateAngle: effectType == .direct ? nil : rotateAngle, zoomScale: effectType == .direct ? nil : zoomScale, renderDirection: renderDirection)
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
                    stepCount = Double(effect.stepCount ?? 30) 
                    effectType = effect.effectType ?? .direct
                    rotateAngle = effect.rotateAngle ?? 0.5
                    rotateDirection = effect.rotateDirection ?? .clockwise
                    zoomScale = effect.zoomScale ?? 1.005
                    startFrame = effect.startFrame
                    renderDirection = effect.renderDirection ?? .forward
                    endFrame = effect.endFrame
                } else {
                    startFrame = store.currentFrameNumber ?? 0
                    endFrame = store.project.lastFrameOfEffect(withStartFrame: startFrame ?? 0)
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
