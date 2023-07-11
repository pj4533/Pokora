//
//  EffectCell.swift
//  Pokora
//
//  Created by PJ Gray on 5/1/23.
//

import SwiftUI

struct EffectCell: View {
    @Binding var effect: Effect
    @EnvironmentObject var store: VideoStore
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(effect.prompt)
                    .font(.title)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                HStack {
                    if effect.effectType == .direct {
                        Image(systemName: "arrowtriangle.forward.square.fill")
                        Text("Direct")
                    } else if effect.effectType == .audioReactive {
                        Image(systemName: "waveform.path")
                        Text("Audio Reactive")
                    } else if effect.effectType == .generative {
                        if effect.renderDirection == .forward {
                            Image(systemName: "arrow.uturn.right.square.fill")
                            Text("Generative")
                        } else {
                            Image(systemName: "arrow.uturn.left.square.fill")
                            Text("Reverse Generative")
                        }
                    }
                }
                .font(.title2)
                .foregroundColor(.secondary)

                HStack {
                    if effect.effectType == .audioReactive {
                        Image(systemName: "arrow.right.square.fill")
                        Text("Threshold: \(String(format: "%.3f", effect.threshold ?? 0.0))")
                    } else {
                        if effect.startStrength == effect.endStrength {
                            Image(systemName: "arrow.right.square.fill")
                            Text("Strength: \(String(format: "%.3f", effect.startStrength))")
                        } else if effect.startStrength < effect.endStrength {
                            Image(systemName: "arrow.up.right.square.fill")
                            Text("Strength: \(String(format: "%.3f ↗ %.3f", effect.startStrength, effect.endStrength))")
                        } else {
                            Image(systemName: "arrow.down.right.square.fill")
                            Text("Strength: \(String(format: "%.3f ↘ %.3f", effect.startStrength, effect.endStrength))")
                        }
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)                
                HStack {
                    Image(systemName: "film.fill")
                    Text("Start: \(numberFormatter.string(from: NSNumber(value: effect.startFrame))!)")
                    Spacer()
                    Text("End: \(numberFormatter.string(from: NSNumber(value: effect.endFrame))!)")
                    Image(systemName: "film.fill")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                let totalFrames = (effect.endFrame - effect.startFrame) + 1
                let progress = totalFrames > 0 ? Double(store.project.getUrls(from: effect).count) / Double(totalFrames) : 0.0
                if progress > 0 {
                    let progressTintColor = progress >= 1 ? Color.green : Color.blue
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: progressTintColor))
                        .frame(height: 8)
                }
            }
            Spacer()
        }
        .padding()
        .cornerRadius(10)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}

struct EffectCell_Previews: PreviewProvider {
    static var previews: some View {
        EffectCell(effect: .constant(Effect(startFrame: 0, endFrame: 999)))
            .environmentObject(VideoStore())
    }
}
