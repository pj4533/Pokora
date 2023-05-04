# Pokora

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)](https://www.apple.com/macos)

<p align="center">
  <img src="Pokora/Assets.xcassets/AppIcon.appiconset/icon-256.png" alt="Pokora icon" />
</p>

Pokora is a video creation platform that combines existing video clips with AI generated video clips, using Stable Diffusion, in a native SwiftUI interface, completely local with no internet access necessary. Pokora uses the frames of an input movie to run image to image processing with a Stable Diffusion model. Check out [ml-stable-diffusion](https://github.com/apple/ml-stable-diffusion) for the latest CoreML model changes and how to convert models.

🧙‍♂️ Pokora is named after Hans Pokora, author of many books on collectable psychedelic vinyl.

## Features

- Load video from disk ✅
- Process frames using Stable Diffusion (prompt, seed, strength) ✅
- Export video including audio from original video ✅
- Need icon ✅
- Need easier install of models ✅
- Playback video in app ✅
- Adjust strength over the course of the video [#7](https://github.com/pj4533/Pokora/issues/7)
- Add up rezzing using RealESRGAN [#8](https://github.com/pj4533/Pokora/issues/8)
- Persist between launches [#16](https://github.com/pj4533/Pokora/issues/16)
- Update to use ControlNET [#10](https://github.com/pj4533/Pokora/issues/10)
- Show preview while processing [#34](https://github.com/pj4533/Pokora/issues/34)
- Multiselect [#36](https://github.com/pj4533/Pokora/issues/36)

## Limitations

- Requires square video as input
- Requires models converted to CoreML (see below)
- Currently using [ml-stable-diffusion](https://github.com/apple/ml-stable-diffusion) v0.3.0

## Requirements

Built using below, but haven't tested elsewhere yet.

- macOS 13.3.1+
- Xcode 14.3+

## Models

You will need to convert or download models in CoreML format. You can download from the HuggingFace org [here](https://huggingface.co/coreml).

NOTE: I had trouble with the v2.1 model, I think it doesn't like the 768x768. I verified this model works [here](https://huggingface.co/coreml/coreml-stable-diffusion-v1-5/blob/main/split-einsum/v1-5_split-einsum.zip), however I have had better speeds with a model I converted myself. 

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

