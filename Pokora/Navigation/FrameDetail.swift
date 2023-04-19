//
//  FrameDetail.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

struct FrameDetail: View {
    @ObservedObject var frame: Frame
    @State private var prompt = ""
    let seed: UInt32 = UInt32.random(in: 0...UInt32.max)
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    if let image = NSImage(contentsOf: frame.inputUrl) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("Error loading source image")
                    }
                }
                Button("Process") {
                    do {
                        frame.outputUrl = try StableDiffusionStore.process(imageUrl: frame.inputUrl, prompt: "a cyberpunk cityscape", strength: 0.2, seed: seed)
                    } catch let error {
                        print(error)
                    }
                }
                VStack {
                    if let url = frame.outputUrl, let image = NSImage(contentsOf: url) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("Error loading processed image")
                    }
                }
            }
            HStack {
                Text("Prompt: ")
                    .fixedSize()
                TextField("A cyberpunk cityscape", text: $prompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            HStack {
                Text("Strength: ")
                    .fixedSize()
                TextField("0.5", text: $prompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
}

struct FrameDetail_Previews: PreviewProvider {
    static var previews: some View {
        FrameDetail(frame: Frame.placeholder)
    }
}
