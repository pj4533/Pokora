//
//  EffectCell.swift
//  Pokora
//
//  Created by PJ Gray on 5/1/23.
//

import SwiftUI

struct EffectCell: View {
    @Binding var effect: Effect
    
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
                    Image(systemName: "arrow.right.square.fill")
                    Text("Strength: \(String(format: "%.3f", effect.strength))")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "number.square.fill")
                    Text("Seed: \(numberFormatter.string(from: NSNumber(value: effect.seed))!)")
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
                
                let totalFrames = effect.endFrame - effect.startFrame
                let progress = totalFrames > 0 ? Double(effect.processedFrames.count) / Double(totalFrames) : 0.0
                let progressTintColor = progress >= 1 ? Color.green : Color.blue
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressTintColor))
                    .frame(height: 8)
                
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
    }
}
