# Epic 2: CoreML Model Preparation 🧠

**Status**: ⏳ Pending
**Phase**: 1 - Foundation
**Duration**: 1-2 days

---

## Overview
Convert the CLIP vision model to CoreML format for on-device inference and create a Swift wrapper service.

**Critical Blocker**: This must be completed before duplicate detection can work!

---

## Tasks

### Task 2.1: Convert CLIP Model to CoreML

**Status**: ⏳ Pending

#### Conversion Script:
- [ ] Create `scripts/convert_clip_to_coreml.py`
- [ ] Implement conversion logic:
  - Load `openai/clip-vit-base-patch32`
  - Extract vision encoder only (no text encoder needed)
  - Trace with PyTorch JIT
  - Convert to CoreML with `coremltools`
  - Target: iOS 17+
  - Output: 512-dimensional embeddings
- [ ] Test conversion locally
  - Run script: `python3 scripts/convert_clip_to_coreml.py`
  - Verify output: `CLIPVisionModel.mlmodel` (~350MB)
- [ ] Validate embeddings match Python
  - Process same test images in Python and CoreML
  - Compare embedding vectors (should be identical)
  - Document any preprocessing differences
- [ ] Optimize model (if needed)
  - Try quantization (FP16) to reduce size
  - Benchmark inference speed
- [ ] Add model to Xcode project
  - Drag `CLIPVisionModel.mlmodel` into Resources/
  - Xcode will auto-generate Swift interface
- [ ] Document model specs
  - Input: 224x224 RGB image
  - Output: 512-dim float array
  - Normalization: ImageNet mean/std

**Python Reference**:
- `src/duplicate_images/ml/feature_extractor.py:35-67` - Preprocessing
- `src/duplicate_images/ml/feature_extractor.py:85-120` - Extraction

---

### Task 2.2: Create Model Wrapper Service

**Status**: ⏳ Pending

**File**: `DuplicatePhotos/Services/EmbeddingService.swift`

#### Subtasks:
- [ ] Create `EmbeddingService.swift`
- [ ] Load CoreML model
  ```swift
  let model = try CLIPVisionModel(configuration: MLModelConfiguration())
  ```
- [ ] Implement image preprocessing
  - Resize to 224x224
  - Normalize RGB values (ImageNet mean/std)
  - Convert UIImage → CVPixelBuffer
- [ ] Extract embedding for single image
  ```swift
  func extractEmbedding(from image: UIImage) async throws -> [Float]
  ```
- [ ] Add batch processing
  ```swift
  func extractEmbeddings(from images: [UIImage], batchSize: Int) async throws -> [[Float]]
  ```
- [ ] Add error handling
  - Model loading failures
  - Invalid images
  - Memory issues
- [ ] Write unit tests
  - Test with sample images
  - Verify embedding dimensions (512)
  - Test batch processing

---

## Definition of Done

- [ ] CLIP model converted to CoreML format
- [ ] Model validated against Python implementation
- [ ] Model added to Xcode project Resources
- [ ] EmbeddingService.swift created and tested
- [ ] Can extract 512-dim embeddings from images
- [ ] Unit tests passing

---

## Dependencies

**Blocks**:
- Task 3.2 (Similarity Service) - needs embeddings
- Task 3.4 (Duplicate Detector) - needs embeddings

**Blocked By**:
- Task 1.1 (Environment Setup) - needs coremltools
- Task 1.2 (Xcode Project) - needs project structure

---

## Success Criteria

- Conversion script runs without errors
- CoreML model produces identical embeddings to Python (within 1e-5 tolerance)
- Inference speed: <100ms per image on iPhone
- Model size: ~350MB (or smaller with optimization)
