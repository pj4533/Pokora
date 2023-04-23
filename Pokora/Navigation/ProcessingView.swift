//
//  ProcessingView.swift
//  Pokora
//
//  Created by PJ Gray on 4/23/23.
//

import SwiftUI

struct ProcessingView: View {
    @Binding var statusText: String
    @Binding var additionalStatusText: String
    var body: some View {
        VStack {
            Text("🧠🧠🧠🧠🧠")
                .font(.largeTitle.bold())
            Text(statusText)
                .foregroundStyle(.secondary)
                .font(.title2.bold())
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Spacer()
                .frame(height: 10.0)
            Text(additionalStatusText)
                .foregroundStyle(.tertiary)
                .font(.title3)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16.0))
    }
}

struct ProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingView(statusText: .constant("Loading"), additionalStatusText: .constant("Test"))
    }
}
