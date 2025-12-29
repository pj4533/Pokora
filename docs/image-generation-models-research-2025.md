# Pokora Image Generation Models Research (2025)

A comprehensive analysis of the current Pokora implementation and the latest advancements in image generation models for video frame processing.

---

## Table of Contents

1. [Current Pokora Architecture](#current-pokora-architecture)
2. [Feature Breakdown & Modern Alternatives](#feature-breakdown--modern-alternatives)
3. [Recommended Local Models for Mac](#recommended-local-models-for-mac)
4. [AWS Self-Hosted Options](#aws-self-hosted-options)
5. [Implementation Roadmap](#implementation-roadmap)
6. [Sources](#sources)

---

## Current Pokora Architecture

### Overview

Pokora is a native macOS app that processes video frames through Stable Diffusion for AI-augmented video effects. It runs completely locally using Apple's Core ML framework.

### Current Tech Stack

| Component | Current Implementation |
|-----------|----------------------|
| **Base Model** | Stable Diffusion v1.5 (CoreML) |
| **Framework** | [Apple ml-stable-diffusion v1.1.0](https://github.com/apple/ml-stable-diffusion) |
| **Resolution** | 512x512 (native) |
| **Upscaling** | RealESRGAN (bundled) |
| **ControlNet** | Optional, single model support |
| **Inference Steps** | 30 (default) |
| **Compute** | CPU + GPU (MLModelConfiguration) |

### Current Workflow

```
Video → Extract Frames (512x512) → Stable Diffusion img2img → Optional Upscale → Export
```

### Effect Types

1. **Direct** - Simple image-to-image on each frame independently
2. **Generative** - Process previous output (enables zoom/rotation effects)
3. **AudioReactive** - Strength modulated by audio RMS amplitude

### Performance Baseline

- M2 MacStudio Ultra: ~7.1 iter/s without ControlNet, ~4.5 iter/s with ControlNet
- 30 steps per frame = ~4 seconds per frame
- 30fps × 30 seconds = 900 frames = ~60 minutes processing time

---

## Feature Breakdown & Modern Alternatives

### 1. Base Image Generation Model

#### Current: Stable Diffusion 1.5
- 860M parameters
- 512x512 native resolution
- Mature ecosystem but outdated quality

#### Modern Alternatives (2025)

| Model | Parameters | Resolution | Steps | Quality | Mac Support |
|-------|-----------|-----------|-------|---------|-------------|
| **SDXL** | 2.6B | 1024x1024 | 25-50 | Excellent | CoreML via Apple |
| **SDXL Lightning** | 2.6B | 1024x1024 | 2-8 | Very Good | LoRA compatible |
| **SDXL Turbo** | 2.6B | 512x512 | 1-4 | Good | Distilled model |
| **Hyper-SDXL** | 2.6B | 1024x1024 | 1-8 | Very Good | LoRA compatible |
| **Flux.1 Dev** | ~12B | 1024x1024 | 20-30 | Best-in-class | MLX/MPS only |
| **Flux.1 Schnell** | ~12B | 1024x1024 | 4 | Very Good | MLX/MPS |
| **SD 3.5** | 2.5B | 1024x1024 | 25-40 | Excellent | CoreML (experimental) |

#### Recommendation: **SDXL with Lightning LoRA**

**Why:**
- 4-8 steps instead of 30 = **7.5x faster**
- Native 1024x1024 resolution (4x more pixels)
- Apple provides [pre-converted CoreML models](https://huggingface.co/apple/coreml-stable-diffusion-xl-base)
- Can use compressed 4.5-bit version (1.4GB vs 4.8GB)
- LoRA form allows using custom checkpoints

**Expected Performance:**
- With Lightning LoRA at 4 steps: ~1 second per frame
- 900 frames = ~15 minutes (vs ~60 minutes currently)

---

### 2. Fast Inference (Few-Step Models)

#### Current: 30 steps per frame

#### Modern Alternatives

| Technique | Steps | Speed Gain | Quality | Notes |
|-----------|-------|-----------|---------|-------|
| **LCM-LoRA** | 2-8 | 4-15x | Good | Works with any SD 1.5/SDXL checkpoint |
| **SDXL Lightning** | 2-8 | 4-15x | Very Good | Best balance of speed/quality |
| **SDXL Turbo** | 1-4 | 7-30x | Good | Fixed 512x512 only |
| **Hyper-SDXL** | 1-8 | 4-30x | Very Good | Often better than Lightning |

#### Recommendation: **LCM-LoRA or SDXL Lightning**

**LCM-LoRA Benefits:**
- Works with existing fine-tuned models
- On M1 Mac: 1024x1024 in ~6 seconds (4 steps) vs ~60 seconds (30 steps)
- [Download from HuggingFace](https://huggingface.co/latent-consistency/lcm-lora-sdxl)

**SDXL Lightning Benefits:**
- Higher quality than LCM at same step count
- Available as LoRA (composable with other LoRAs)
- [Download from ByteDance](https://huggingface.co/ByteDance/SDXL-Lightning)

---

### 3. ControlNet

#### Current: Basic ControlNet support (single model)

#### Modern Alternatives (2025)

**For SDXL:**
- [ControlNet++](https://huggingface.co/bdsqlsz/qinglong_controlnet-lllite) - All-in-one model supporting multiple control types
- Individual models: Canny, Depth, OpenPose, Tile, Lineart, Softedge, Recolor
- [Civitai ControlNetXL Collection](https://civitai.com/models/136070/controlnetxl-cnxl) - Community maintained

**For Flux:**
- [XLabs-AI Flux ControlNet](https://huggingface.co/XLabs-AI/flux-controlnet-collections) - v3 versions available
- **InstantX Flux Union ControlNet** - Multi-mode support (Canny, Tile, Depth, Blur, Pose)

#### Recommendation: **SDXL ControlNet++ or Union Model**

**Why:**
- Single model file for multiple control types
- Reduces disk space and model switching overhead
- Better integration with existing CoreML pipeline

---

### 4. Upscaling

#### Current: RealESRGAN (bundled 512→higher)

#### Modern Alternatives (2025)

| Model | Scale | Quality | Speed | Best For |
|-------|-------|---------|-------|----------|
| **RealESRGAN** | 4x | Good | Fast | General purpose |
| **SwinIR** | 4x | Best | Slow | Fine art, archival |
| **4x UltraSharp** | 4x | Excellent | Medium | Sharp digital art |
| **PMRF** | 2x | Very Good | Fast | Low VRAM (3.3GB) |

#### Recommendation: **Keep RealESRGAN, consider SwinIR for quality mode**

**Why:**
- RealESRGAN is still the best speed/quality balance
- SwinIR for a "quality priority" export option
- With SDXL at 1024x1024, upscaling becomes less critical

---

### 5. Frame Interpolation (NEW FEATURE)

#### Current: Not implemented

#### Modern Options (2025)

| Model | Speed | Quality | Best For |
|-------|-------|---------|----------|
| **RIFE v4.7+** | Real-time | Very Good | General video, anime |
| **FILM** | Slow | Best | Complex motion, occlusions |
| **RIFE v4.22.lite** | Fast | Good | Diffusion model outputs |

#### Recommendation: **Add RIFE interpolation**

**Why:**
- Process at 15fps, interpolate to 30fps = half the inference work
- RIFE runs 30+ FPS on GPU (essentially free)
- [Flowframes](https://nmkd.itch.io/flowframes) - Open source wrapper
- Best workflow: Interpolate THEN upscale (not the reverse)

---

### 6. Style Transfer (NEW FEATURE)

#### Current: Prompt-based only

#### Modern Options (2025)

| Technique | Description | Quality |
|-----------|-------------|---------|
| **IP-Adapter** | Image prompt adapter for style/composition | Excellent |
| **IP-Adapter Plus** | Enhanced version with better style separation | Best |
| **Flux Redux** | Official Black Forest Labs style transfer | Excellent |

#### Recommendation: **Add IP-Adapter support for SDXL**

**Why:**
- Reference image as style guide (no prompt needed)
- Separate style from composition transfer
- Scale parameter for blending (0.5 typical)
- [GitHub: tencent-ailab/IP-Adapter](https://github.com/tencent-ailab/IP-Adapter)

---

## Recommended Local Models for Mac

### Tier 1: Best Overall (M1/M2/M3 Pro/Max with 32GB+)

```
Model: SDXL with Lightning LoRA (4-step)
Framework: Apple ml-stable-diffusion (CoreML)
Resolution: 1024x1024
Expected Speed: ~1-2 sec/frame
Memory: ~5GB VRAM
```

**Download:**
- Base: [apple/coreml-stable-diffusion-xl-base](https://huggingface.co/apple/coreml-stable-diffusion-xl-base)
- Compressed: [apple/coreml-stable-diffusion-mixed-bit-palettization](https://huggingface.co/apple/coreml-stable-diffusion-mixed-bit-palettization) (1.4GB)

### Tier 2: Maximum Quality (M2/M3 Max/Ultra with 64GB+)

```
Model: Flux.1 Dev (via MLX)
Framework: DiffusionKit or MLX
Resolution: 1024x1024
Expected Speed: ~2-5 min/frame
Memory: ~24GB
```

**Why Flux:**
- Best text rendering (handles prompts with text correctly)
- Best hand generation
- Best pose accuracy
- Superior to all SD variants in quality

**Download:**
- [argmaxinc/mlx-FLUX.1-dev](https://huggingface.co/argmaxinc/DiffusionKit) via DiffusionKit
- Use Q6 quantization for 16GB+ systems

### Tier 3: Speed Priority (Any Apple Silicon)

```
Model: SDXL Turbo
Framework: CoreML or MPS
Resolution: 512x512
Expected Speed: ~0.5-1 sec/frame
Memory: ~4GB
```

**Tradeoffs:**
- Locked to 512x512
- No negative prompts
- CFG must be 1-2

---

## AWS Self-Hosted Options

### Instance Recommendations

| Instance | GPU | VRAM | On-Demand | Spot | Best For |
|----------|-----|------|-----------|------|----------|
| **g4dn.xlarge** | T4 | 16GB | $0.53/hr | ~$0.16/hr | SD 1.5, SDXL |
| **g5.xlarge** | A10G | 24GB | $1.01/hr | ~$0.35/hr | SDXL, Flux Schnell |
| **g5.2xlarge** | A10G | 24GB | $1.21/hr | ~$0.40/hr | Flux Dev |
| **p4d.24xlarge** | 8×A100 | 320GB | $32.77/hr | ~$12/hr | Batch processing |

### Cost Analysis: Processing 30s Video (900 frames)

| Setup | Time | Cost |
|-------|------|------|
| **g4dn.xlarge + SDXL Turbo** | ~15 min | ~$0.13 |
| **g5.xlarge + SDXL Lightning** | ~20 min | ~$0.34 |
| **g5.xlarge + Flux Schnell** | ~60 min | ~$1.00 |
| **Mac M2 Max (local)** | ~15-60 min | $0 (electricity only) |

### Recommended Setup

```bash
# Use Spot instances for 70% savings
# Pre-built AMI: AWS Marketplace "Stable Diffusion"
# Or use ComfyUI Docker container

# Example workflow:
1. Upload video to S3
2. Spin up g5.xlarge spot instance
3. Process with SDXL Lightning (4 steps)
4. Download results
5. Terminate instance

# Monthly budget for ~70,000 images: ~$310
```

### Alternative Cloud Providers (Cheaper)

| Provider | GPU | Price | Notes |
|----------|-----|-------|-------|
| **Lambda Labs** | A100 40GB | $1.29/hr | Simple pricing |
| **Lambda Labs** | A6000 | $0.80/hr | Good for SDXL |
| **Vast.ai** | Various | $0.20-2.00/hr | Marketplace model |
| **RunPod** | Various | $0.20-2.00/hr | Pre-built templates |

---

## Implementation Roadmap

### Phase 1: Upgrade to SDXL (High Impact)

**Changes Required:**

1. **Update ml-stable-diffusion dependency** to latest version
   - Current: v1.1.0
   - Check for latest: [GitHub releases](https://github.com/apple/ml-stable-diffusion/releases)

2. **Download SDXL CoreML models**
   ```swift
   // Update pipeline initialization
   let resourceURL = URL(filePath: "model_output/Resources-SDXL")
   self.pipeline = try StableDiffusionPipeline(
       resourcesAt: resourceURL,
       controlNet: controlNet,
       configuration: config,
       disableSafety: true,
       reduceMemory: false
   )
   ```

3. **Update frame extraction resolution**
   ```swift
   // Change from 512x512 to 1024x1024
   let targetSize = CGSize(width: 1024, height: 1024)
   ```

4. **Add `--xl` flag support** for pipeline configuration

**Files to Modify:**
- `VideoStore+StableDiffusion.swift` - Pipeline initialization
- `VideoStore+Video.swift` - Frame extraction size
- `VideoStore+Effects.swift` - Possibly adjust defaults
- `Effect.swift` - Add resolution option

### Phase 2: Add Fast Inference (High Impact)

**Add LCM-LoRA or Lightning Support:**

1. **Download Lightning LoRA models** from [ByteDance](https://huggingface.co/ByteDance/SDXL-Lightning)

2. **Update step count options**
   ```swift
   // In Effect.swift, add preset options
   enum InferenceSpeed: String, CaseIterable {
       case fast = "Fast (4 steps)"      // Lightning/LCM
       case balanced = "Balanced (8 steps)"
       case quality = "Quality (20 steps)"
   }
   ```

3. **Adjust guidance scale** for distilled models
   ```swift
   // Lightning/LCM needs lower CFG
   let guidanceScale: Float = isDistilledModel ? 1.5 : 7.5
   ```

### Phase 3: Frame Interpolation (Medium Impact)

**Add RIFE integration:**

1. Process at half framerate (15fps for 30fps output)
2. Run RIFE as post-processing step
3. Use [RIFE NCNN Vulkan](https://github.com/nihui/rife-ncnn-vulkan) for Mac

**Workflow Change:**
```
Extract at 15fps → SD Processing → RIFE 2x → Export at 30fps
```

### Phase 4: Enhanced ControlNet (Medium Impact)

**Upgrade ControlNet support:**

1. Support multiple ControlNet models simultaneously
2. Add preprocessors (Canny, Depth extraction) in-app
3. Add strength/guidance per ControlNet

### Phase 5: IP-Adapter / Style Transfer (Low-Medium Impact)

**Add reference image support:**

1. Integrate IP-Adapter SDXL models
2. Add UI for selecting reference style image
3. Implement scale parameter (0.0 - 1.0)

### Phase 6: Flux Support (Future/Optional)

**When CoreML support matures:**

1. Wait for official Apple support or stable community conversions
2. Requires significant VRAM (32GB+ recommended)
3. Best quality but ~4x slower than SDXL Lightning

---

## Quick Reference: Model Download Links

### CoreML (Apple Silicon Native)

| Model | Link | Size |
|-------|------|------|
| SDXL Base | [apple/coreml-stable-diffusion-xl-base](https://huggingface.co/apple/coreml-stable-diffusion-xl-base) | 4.8GB |
| SDXL Compressed | [apple/coreml-stable-diffusion-mixed-bit-palettization](https://huggingface.co/apple/coreml-stable-diffusion-mixed-bit-palettization) | 1.4GB |
| SD 1.5 | [apple/coreml-stable-diffusion-v1-5](https://huggingface.co/apple/coreml-stable-diffusion-v1-5) | ~2GB |

### LoRAs (Speed Optimization)

| Model | Link | Steps |
|-------|------|-------|
| LCM-LoRA SDXL | [latent-consistency/lcm-lora-sdxl](https://huggingface.co/latent-consistency/lcm-lora-sdxl) | 2-8 |
| SDXL Lightning | [ByteDance/SDXL-Lightning](https://huggingface.co/ByteDance/SDXL-Lightning) | 2-8 |
| Hyper-SDXL | [ByteDance/Hyper-SD](https://huggingface.co/ByteDance/Hyper-SD) | 1-8 |

### ControlNet

| Model | Link |
|-------|------|
| SDXL ControlNets | [bdsqlsz/qinglong_controlnet-lllite](https://huggingface.co/bdsqlsz/qinglong_controlnet-lllite) |
| Flux ControlNets | [XLabs-AI/flux-controlnet-collections](https://huggingface.co/XLabs-AI/flux-controlnet-collections) |

### Flux (MLX)

| Model | Link | Notes |
|-------|------|-------|
| Flux Schnell | [argmaxinc/mlx-FLUX.1-schnell](https://huggingface.co/argmaxinc/DiffusionKit) | 4 steps |
| Flux Dev | [argmaxinc/mlx-FLUX.1-dev](https://huggingface.co/argmaxinc/DiffusionKit) | 20-30 steps |

---

## Sources

### Apple & CoreML
- [Apple ML Research: Stable Diffusion on Apple Silicon](https://machinelearning.apple.com/research/stable-diffusion-coreml-apple-silicon)
- [GitHub: apple/ml-stable-diffusion](https://github.com/apple/ml-stable-diffusion)
- [HuggingFace: SDXL CoreML Quantization](https://huggingface.co/blog/stable-diffusion-xl-coreml)

### Model Comparisons
- [Baseten: Comparing Few-Step Models](https://www.baseten.co/blog/comparing-few-step-image-generation-models/)
- [Stable Diffusion Art: SDXL vs Flux](https://stable-diffusion-art.com/sdxl-vs-flux/)
- [Apatero: Flux on Apple Silicon Guide](https://apatero.com/blog/flux-apple-silicon-m1-m2-m3-m4-complete-performance-guide-2025)

### Fast Inference
- [HuggingFace: LCM-LoRA SDXL](https://huggingface.co/blog/lcm_lora)
- [ByteDance: SDXL-Lightning](https://huggingface.co/ByteDance/SDXL-Lightning)
- [Stable Diffusion Art: Hyper-SDXL](https://stable-diffusion-art.com/hyper-sdxl/)

### Upscaling & Interpolation
- [Apatero: ESRGAN Comparison 2025](https://apatero.com/blog/fastest-esrgan-upscaling-models-quality-comparison-2025)
- [Apatero: RIFE vs FILM Comparison](https://apatero.com/blog/rife-vs-film-video-frame-interpolation-comparison-2025)

### Cloud GPU
- [AWS Extension for Stable Diffusion](https://awslabs.github.io/stable-diffusion-aws-extension/en/cost/)
- [Stable Diffusion Art: AWS EC2 Setup](https://stable-diffusion-art.com/aws-ec2/)

### Style Transfer
- [GitHub: IP-Adapter](https://github.com/tencent-ailab/IP-Adapter)
- [Stable Diffusion Art: IP-Adapter Guide](https://stable-diffusion-art.com/ip-adapter/)

### Native Mac Apps
- [GitHub: MochiDiffusion](https://github.com/MochiDiffusion/MochiDiffusion)
- [GitHub: DiffusionKit](https://github.com/argmaxinc/DiffusionKit)
- [HuggingFace: Swift Diffusers](https://huggingface.co/blog/fast-mac-diffusers)

---

*Document generated: December 2025*
*Last updated: December 29, 2025*
