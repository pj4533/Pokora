//
//  EffectCell.swift
//  Pokora
//
//  Created by PJ Gray on 5/1/23.
//

import SwiftUI

struct EffectCell: View {
    @Binding var effect: Effect
    var body: some View {
        VStack(alignment: .leading) {
            Text(effect.prompt)
            Text("Strength: \(effect.strength)")
            Text("Seed: \(effect.seed)")
            Text("Start: \(effect.startFrame)")
            Text("End: \(effect.endFrame)")
        }
    }
}

struct EffectCell_Previews: PreviewProvider {
    static var previews: some View {
        EffectCell(effect: .constant(Effect(startFrame: 0, endFrame: 999)))
    }
}
