//
//  ProcessingView.swift
//  Pokora
//
//  Created by PJ Gray on 4/23/23.
//

import SwiftUI

struct ProcessingView: View {
    @Binding var statusText: String
    var body: some View {
        VStack {
            ProgressView() // This creates a spinner by default
                .progressViewStyle(CircularProgressViewStyle())
            Text(statusText)
        }
    }
}

struct ProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingView(statusText: .constant("Loading"))
    }
}
