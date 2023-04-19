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
                ZStack {
                    Color.clear
                        .frame(width: 512, height: 512)
                    if let url = frame.inputUrl, let image = NSImage(contentsOf: url) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 512, height: 512)
                    } else {
                        VStack {
                            Image(systemName: "video.slash.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.primary)
                            Spacer()
                                .frame(height: 50)
                            Text("No frame loaded")
                        }
                    }
                }
                Button("Process") {
                    if let url = frame.inputUrl {
                        do {
                            frame.outputUrl = try StableDiffusionStore.process(imageUrl: url, prompt: "a cyberpunk cityscape", strength: 0.2, seed: seed)
                        } catch let error {
                            print(error)
                        }
                    }
                }
                .frame(width: 80.0)
                ZStack {
                    Color.clear
                        .frame(width: 512, height: 512)
                    if let url = frame.outputUrl, let image = NSImage(contentsOf: url) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 512, height: 512)
                    } else {
                        VStack {
                            Image(systemName: "video.slash.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.primary)
                            Spacer()
                                .frame(height: 50)
                            Text("Frame not processed")
                        }
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
