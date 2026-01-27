# Architecture Patterns: iOS Duplicate Photo Detection

**Domain:** iOS duplicate photo detection using CoreML embeddings
**Researched:** 2026-01-27
**Overall confidence:** HIGH

## Executive Summary

The duplicate photo detection pipeline requires careful attention to **CoreML model output dimensions** and **proper Vision framework integration**. The critical issue identified: the converted CLIP model outputs **768-dimensional embeddings** (pooler_output) instead of **512-dimensional projected embeddings** (image_features), causing dimension mismatches and zero similarity scores.

**Key architectural finding:** Using `CLIPVisionModel` directly (which only has pooler_output) instead of the full `CLIPModel` (which includes the projection layer) is the root cause. The Python reference uses `CLIPModel.get_image_features()` which applies the 768→512 projection, but the iOS conversion only wraps `CLIPVisionModel` which outputs raw 768-dim pooler_output.

## Recommended Architecture

### Pipeline Overview

```
PHAsset → UIImage → CoreML Model → Embedding Vector → Cosine Similarity → Duplicate Groups
   ↓          ↓           ↓              ↓                    ↓                ↓
PhotoLib   Resize    VNCoreML/      Normalize           vDSP_dotpr      Connected
Service    224x224   MLModel        (L2 norm)                           Components
```

### Component Boundaries

| Component | Responsibility | Input | Output | Critical Details |
|-----------|---------------|-------|--------|-----------------|
| **PhotoLibraryService** | Fetch PHAssets, load images | PHAsset query | PHAsset array, UIImage | Use `.centerCrop` for aspect ratio preservation |
| **EmbeddingService** | Extract embeddings via CoreML | UIImage (224x224) | [Float] (512-dim) | **MUST use model with projection layer** |
| **SimilarityService** | Compute cosine similarity | Two embeddings | Float (0-1) | Use Accelerate vDSP for performance |
| **DuplicateDetector** | Orchestrate pipeline, group results | ScanSettings | [DuplicateGroup] | Implements connected components (DFS) |
| **CacheService** | Persist embeddings | Embedding + assetID | CachedEmbedding | Avoids recomputation on re-scan |

## Data Flow Details

### 1. Photo Library Access

```swift
// Correct PHAsset fetching pattern
let fetchOptions = PHFetchOptions()
fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
```

**Key consideration:** Use `.limited` authorization status for privacy-conscious users (iOS 14+).

### 2. Image Loading and Preprocessing

```swift
// Correct image loading for embedding extraction
let targetSize = CGSize(width: 224, height: 224)
let options = PHImageRequestOptions()
options.deliveryMode = .highQualityFormat
options.isNetworkAccessAllowed = true  // Important for iCloud photos
options.isSynchronous = false

PHImageManager.default().requestImage(
    for: asset,
    targetSize: targetSize,
    contentMode: .aspectFill,  // Matches .centerCrop in Vision
    options: options
)
```

**Critical:** The `contentMode: .aspectFill` combined with Vision's `.centerCrop` ensures consistent preprocessing matching the Python reference.

### 3. Embedding Extraction: TWO APPROACHES

#### Approach A: VNCoreMLRequest (Current - BROKEN)

**Issue:** VNCoreMLRequest works but reveals the underlying model dimension mismatch.

```swift
// Current implementation (has dimension issues)
let request = VNCoreMLRequest(model: model)
request.imageCropAndScaleOption = .centerCrop

let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try handler.perform([request])

guard let results = request.results as? [VNCoreMLFeatureValueObservation],
      let firstResult = results.first,
      let multiArray = firstResult.featureValue.multiArrayValue else {
    throw EmbeddingError.predictionFailed
}

// Extract embedding - PROBLEM: multiArray.count is 768, not 512!
var embedding = [Float](repeating: 0, count: embeddingDimension)
for i in 0..<embeddingDimension {
    embedding[i] = Float(truncating: multiArray[i])
}
```

**What's wrong:**
1. Model outputs 768 dimensions (pooler_output from CLIPVisionModel)
2. Code expects 512 dimensions (hardcoded `embeddingDimension = 512`)
3. Current code only reads first 512 of 768 values, discarding 256 dimensions
4. Embeddings are incomplete and non-comparable to properly extracted 512-dim vectors

**Why VNCoreMLRequest adds complexity:**
- Vision framework adds preprocessing (good: handles image scaling)
- Vision framework wraps outputs in VNCoreMLFeatureValueObservation (neutral)
- Vision framework doesn't fix underlying model architecture issues (bad: masks the real problem)

#### Approach B: Direct MLModel Prediction (RECOMMENDED)

**Advantage:** More explicit control, reveals dimension mismatches immediately.

```swift
// Direct CoreML prediction (more explicit)
guard let modelURL = Bundle.main.url(forResource: "CLIPVision", withExtension: "mlmodelc"),
      let model = try? MLModel(contentsOf: modelURL) else {
    throw EmbeddingError.modelNotFound
}

// Prepare image as CVPixelBuffer or MLFeatureValue
let imageFeature = try MLFeatureValue(cgImage: cgImage, constraint: imageConstraint)
let input = try MLDictionaryFeatureProvider(dictionary: ["image": imageFeature])

let prediction = try model.prediction(from: input)
guard let embeddingArray = prediction.featureValue(for: "embedding")?.multiArrayValue else {
    throw EmbeddingError.predictionFailed
}

// Dimension is explicit from model spec
print("Embedding dimension: \(embeddingArray.count)")  // Reveals 768 immediately
```

**When to use each:**
- **VNCoreMLRequest:** Classification models, object detection, models with complex preprocessing
- **Direct MLModel:** Embedding extraction, feature vectors, when you need explicit dimension control

**Recommendation for this project:** Direct MLModel is clearer for debugging the dimension mismatch issue.

### 4. The CoreML Model Architecture Problem

**Root cause identified from model inspection:**

```bash
# Model spec shows:
Outputs: [name: "embedding", dimension: 768]  # NOT 512!
```

**Why 768 instead of 512?**

The Python conversion script uses:

```python
class CLIPVisionWrapper(nn.Module):
    def __init__(self, clip_model):
        super().__init__()
        self.model = clip_model

    def forward(self, pixel_values):
        outputs = self.model(pixel_values)
        return outputs.pooler_output  # ← This is 768-dim!
```

**The Python reference uses:**

```python
# From feature_extractor.py
image_features = self.model.get_image_features(**inputs)  # ← This is 512-dim!
```

**The difference:**

| Method | Class | Output | Dimension | Has Projection? |
|--------|-------|--------|-----------|-----------------|
| `pooler_output` | CLIPVisionModel | Vision encoder hidden state | 768 | NO |
| `get_image_features()` | CLIPModel (full) | Projected embeddings | 512 | YES (768→512) |

**CLIP architecture:**

```
Image (224x224)
    ↓
ViT Encoder (patches, attention layers)
    ↓
pooler_output [768-dim] ← CLIPVisionModel stops here
    ↓
Projection Layer (Linear: 768 → 512)
    ↓
image_embeds [512-dim] ← CLIPModel.get_image_features() outputs this
    ↓
Normalized for contrastive loss
```

**Source:** [CLIP Hugging Face Documentation](https://huggingface.co/docs/transformers/model_doc/clip) explains that `get_image_features()` applies the projection layer to pooler_output, while [Hugging Face Forums discussion](https://discuss.huggingface.co/t/last-hidden-state-vs-pooler-output-in-clipvisionmodel/26281) confirms pooler_output is 768-dim and image_embeds is 512-dim.

### 5. CORRECT Model Conversion

**Fixed conversion script:**

```python
import torch
import torch.nn as nn
from transformers import CLIPModel, CLIPProcessor
import coremltools as ct

class CLIPImageEmbedding(nn.Module):
    """Extract 512-dim projected embeddings (not just pooler_output)"""
    def __init__(self, clip_model):
        super().__init__()
        self.vision_model = clip_model.vision_model
        self.visual_projection = clip_model.visual_projection  # ← KEY: Include projection

    def forward(self, pixel_values):
        # Get vision encoder output (768-dim)
        vision_outputs = self.vision_model(pixel_values)
        pooler_output = vision_outputs.pooler_output

        # Apply projection layer (768 → 512)
        image_embeds = self.visual_projection(pooler_output)

        return image_embeds

# Load FULL CLIPModel (not just CLIPVisionModel)
model_name = "openai/clip-vit-base-patch32"
clip_model = CLIPModel.from_pretrained(model_name)
model = CLIPImageEmbedding(clip_model)
model.eval()

# Convert to CoreML
example_input = torch.randn(1, 3, 224, 224)
traced_model = torch.jit.trace(model, example_input)

mlmodel = ct.convert(
    traced_model,
    inputs=[ct.ImageType(name="image", shape=(1, 3, 224, 224))],
    outputs=[ct.TensorType(name="embedding")],  # Will be 512-dim now
    convert_to="mlprogram",
    minimum_deployment_target=ct.target.iOS17
)
```

**Verification after conversion:**

```bash
python3 -c "import coremltools as ct; model = ct.models.MLModel('CLIPVision.mlpackage'); \
print(model.get_spec().description.output)"
# Should show: dimension: 512 (not 768)
```

### 6. Similarity Computation

**Current implementation (CORRECT):**

```swift
func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
    guard a.count == b.count else { return 0.0 }

    var dotProduct: Float = 0.0
    vDSP_dotpr(a, 1, b, 1, &dotProduct, vDSP_Length(a.count))

    var normA: Float = 0.0
    var normB: Float = 0.0
    vDSP_svesq(a, 1, &normA, vDSP_Length(a.count))
    vDSP_svesq(b, 1, &normB, vDSP_Length(b.count))

    let denominator = sqrt(normA) * sqrt(normB)
    guard denominator > 0 else { return 0.0 }

    return dotProduct / denominator
}
```

**Verification note:** If embeddings are L2-normalized (magnitude = 1), then:
```
cosine_similarity = dot_product (when both vectors are normalized)
```

**Current normalization (CORRECT):**

```swift
private func normalizeEmbedding(_ embedding: [Float]) -> [Float] {
    let sum = embedding.reduce(0) { $0 + ($1 * $1) }
    let magnitude = sqrt(sum)
    guard magnitude > 0 else { return embedding }
    return embedding.map { $0 / magnitude }
}
```

**Optimization opportunity (use Accelerate):**

```swift
private func normalizeEmbedding(_ embedding: [Float]) -> [Float] {
    var normalized = embedding
    var magnitude: Float = 0.0

    // Sum of squares using vDSP
    vDSP_svesq(embedding, 1, &magnitude, vDSP_Length(embedding.count))
    magnitude = sqrt(magnitude)

    guard magnitude > 0 else { return embedding }

    // Divide by scalar using vDSP
    vDSP_vsdiv(embedding, 1, &magnitude, &normalized, 1, vDSP_Length(embedding.count))

    return normalized
}
```

### 7. Connected Components Grouping

**Current implementation (CORRECT):**

The DFS-based connected components algorithm correctly:
1. Builds adjacency graph from similar pairs (threshold ≥ 0.90)
2. Uses DFS to find connected components
3. Filters out single-node components (not duplicates)
4. Returns groups sorted by size

**No changes needed** - this matches the Python reference implementation.

## Architecture Patterns to Follow

### Pattern 1: Actor Isolation for Services

**What:** All services are `actor` types for thread-safe concurrent access
**When:** Photo processing is inherently concurrent (multiple images in parallel)
**Example:**

```swift
actor EmbeddingService {
    private var model: MLModel?

    func extractEmbedding(from image: UIImage) async throws -> [Float] {
        // Actor ensures thread-safe model access
    }
}
```

**Why:** PHAsset operations, CoreML inference, and cache access all benefit from structured concurrency without manual lock management.

### Pattern 2: Separation of Model Loading from Inference

**What:** Lazy model loading with `ensureModelLoaded()` pattern
**When:** Model is 350MB+ and expensive to initialize
**Example:**

```swift
actor EmbeddingService {
    private var model: MLModel?
    private var isModelLoaded = false

    private func ensureModelLoaded() async throws {
        guard !isModelLoaded else { return }
        // Load model once, reuse for all predictions
    }
}
```

**Why:** Avoid loading model multiple times, but don't block initialization if model isn't immediately needed.

### Pattern 3: Progressive Feedback via Progress Handlers

**What:** Async callbacks reporting progress during long operations
**When:** Scanning 1000+ photos takes 10-60 seconds
**Example:**

```swift
typealias ProgressHandler = @Sendable (Int, Int) -> Void

func scanForDuplicates(
    settings: ScanSettings,
    progress: ProgressHandler? = nil
) async throws -> [DuplicateGroup] {
    for (index, asset) in assets.enumerated() {
        // Process asset
        progress?(index + 1, assets.count)
    }
}
```

**Why:** User feedback for long operations, SwiftUI binding for progress bars.

### Pattern 4: Cache Invalidation via Image Hash

**What:** Compare image hash to detect if cached embedding is stale
**When:** Photo edited after initial scan
**Example:**

```swift
struct CachedEmbedding {
    let assetIdentifier: String
    let embedding: [Float]
    let imageHash: String      // For invalidation
    let createdAt: Date
}

// Check cache validity
if let cached = cache.get(assetID),
   cached.imageHash == currentHash {
    return cached.embedding
}
```

**Why:** Embeddings are expensive to compute but deterministic for a given image. Invalidate cache only when image changes.

### Pattern 5: Embedding Normalization at Extraction Time

**What:** L2-normalize embeddings immediately after extraction
**When:** Every embedding extraction
**Example:**

```swift
func extractEmbedding(from image: UIImage) async throws -> [Float] {
    let rawEmbedding = try await runModelInference(image)
    return normalizeEmbedding(rawEmbedding)  // Always normalize
}
```

**Why:**
- Cosine similarity requires normalized vectors for accurate comparison
- Normalization at extraction time (not comparison time) avoids repeated normalization
- Normalized embeddings can be stored directly in cache

## Anti-Patterns to Avoid

### Anti-Pattern 1: Using CLIPVisionModel Instead of CLIPModel

**What goes wrong:** Outputs 768-dim pooler_output instead of 512-dim projected embeddings
**Why it happens:** CLIPVisionModel seems like the right choice for "vision only" task
**Consequences:**
- Dimension mismatch with Python reference
- Embeddings not in same latent space as text (if text search added later)
- Non-comparable to CLIP embeddings from other sources

**Instead:** Use full `CLIPModel` and extract `visual_projection` layer, or use `get_image_features()` equivalent.

### Anti-Pattern 2: Using VNCoreMLRequest for Everything

**What goes wrong:** VNCoreMLRequest adds abstraction that can hide issues
**Why it happens:** Vision framework is designed for classification/detection, feels "proper"
**Consequences:**
- Harder to debug dimension mismatches
- Adds unnecessary observation wrapping for simple tensor outputs
- Image preprocessing (while helpful) can differ from training preprocessing

**Instead:** Use direct `MLModel.prediction()` for embedding extraction, use VNCoreMLRequest for classification tasks.

**When VNCoreMLRequest IS appropriate:**
- Object detection (VNRecognizedObjectObservation)
- Image classification (VNClassificationObservation)
- Complex preprocessing needed (face detection, text detection)

### Anti-Pattern 3: Comparing Non-Normalized Embeddings

**What goes wrong:** Cosine similarity formula requires normalized vectors
**Why it happens:** Model outputs aren't guaranteed to be normalized
**Consequences:**
- Similarity scores don't fall in [0, 1] range
- Magnitude differences dominate similarity (brighter images score higher)

**Instead:** Always L2-normalize embeddings after extraction.

### Anti-Pattern 4: Using .scaleFill for Image Preprocessing

**What goes wrong:** Image distortion changes semantic content
**Why it happens:** `.scaleFill` stretches image to exact dimensions
**Consequences:**
- Aspect ratio changes create different visual features
- Embeddings don't match Python reference (which uses center crop)

**Instead:** Use `.centerCrop` (VNCoreMLRequest) or `.aspectFill` (PHImageManager).

### Anti-Pattern 5: Hardcoding Embedding Dimension

**What goes wrong:** Silently truncates or pads embeddings when model changes
**Why it happens:** 512 is "known" dimension for CLIP
**Consequences:**
- Current code only reads first 512 of 768 values
- No error thrown, just wrong embeddings

**Instead:** Read dimension from model spec:

```swift
let modelDescription = model.modelDescription
if let outputDescription = modelDescription.outputDescriptionsByName["embedding"],
   let multiArrayConstraint = outputDescription.multiArrayConstraint {
    let shape = multiArrayConstraint.shape
    let embeddingDim = shape[1].intValue  // [1, 512] → 512
}
```

### Anti-Pattern 6: Synchronous PHImageManager Requests

**What goes wrong:** Main thread blocking during image loading
**Why it happens:** Setting `isSynchronous = true` seems simpler
**Consequences:**
- UI freezes during photo library scans
- Defeats async/await architecture

**Instead:** Always use `isSynchronous = false` with async continuations.

### Anti-Pattern 7: Forgetting iCloud Photos

**What goes wrong:** Image loading fails for iCloud-only photos
**Why it happens:** Default PHImageRequestOptions doesn't fetch from network
**Consequences:**
- Scan fails for users with iCloud Photo Library enabled
- Incomplete duplicate detection

**Instead:** Always set `isNetworkAccessAllowed = true`:

```swift
let options = PHImageRequestOptions()
options.isNetworkAccessAllowed = true  // Critical for iCloud photos
```

## Verification Steps for Each Pipeline Stage

### Stage 1: Photo Library Access
```swift
// Verify authorization
let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
print("Authorization status: \(status.rawValue)")  // Should be 3 (.authorized)

// Verify asset count
let assets = try await photoLibrary.fetchAllPhotos()
print("Total assets: \(assets.count)")  // Should match Photos app count
```

### Stage 2: Image Loading
```swift
// Verify image dimensions
let image = try await photoLibrary.loadImage(for: asset, targetSize: CGSize(width: 224, height: 224))
print("Image size: \(image.size)")  // Should be 224x224
print("Image scale: \(image.scale)")  // Should be 1.0
```

### Stage 3: Model Loading
```swift
// Verify model file exists
guard let modelURL = Bundle.main.url(forResource: "CLIPVision", withExtension: "mlmodelc") else {
    fatalError("Model not found in bundle")
}
print("Model URL: \(modelURL)")

// Verify model can load
let model = try MLModel(contentsOf: modelURL)
print("Model loaded: \(model.modelDescription.metadata[.description] ?? "no description")")
```

### Stage 4: Embedding Extraction
```swift
// Verify embedding dimension
let embedding = try await embeddingService.extractEmbedding(from: image)
print("Embedding dimension: \(embedding.count)")  // MUST be 512, not 768

// Verify normalization
let magnitude = sqrt(embedding.reduce(0) { $0 + ($1 * $1) })
print("Embedding magnitude: \(magnitude)")  // Should be ~1.0 (normalized)

// Verify non-zero values
let nonZero = embedding.filter { abs($0) > 0.001 }.count
print("Non-zero values: \(nonZero)/\(embedding.count)")  // Should be high percentage

// Verify value range (after normalization)
let maxVal = embedding.max() ?? 0
let minVal = embedding.min() ?? 0
print("Value range: [\(minVal), \(maxVal)]")  // Should be roughly [-1, 1]
```

### Stage 5: Similarity Computation
```swift
// Verify self-similarity
let embedding1 = try await embeddingService.extractEmbedding(from: image)
let embedding2 = try await embeddingService.extractEmbedding(from: image)  // Same image
let similarity = await similarityService.cosineSimilarity(embedding1, embedding2)
print("Self-similarity: \(similarity)")  // Should be ~1.0 (may vary slightly due to image loading)

// Verify different image similarity
let otherImage = try await photoLibrary.loadImage(for: differentAsset)
let embedding3 = try await embeddingService.extractEmbedding(from: otherImage)
let diff_similarity = await similarityService.cosineSimilarity(embedding1, embedding3)
print("Different image similarity: \(diff_similarity)")  // Should be < 0.90 for non-duplicates
```

### Stage 6: Duplicate Detection
```swift
// Verify pair finding
let pairs = await similarityService.findSimilarPairs(photos: photoAssets, threshold: 0.90)
print("Similar pairs found: \(pairs.count)")

// Verify grouping
let groups = detector.reconstructGroups(from: pairs, photos: photoAssets)
print("Duplicate groups: \(groups.count)")
print("Largest group size: \(groups.first?.count ?? 0)")
```

## Debugging Checklist

When pipeline finds no duplicates:

- [ ] **Model dimension:** Verify embedding dimension is 512 (not 768)
- [ ] **Model output:** Inspect `CLIPVision.mlpackage` spec to confirm output shape
- [ ] **Embedding extraction:** Print first 5 values of embedding to verify non-zero
- [ ] **Normalization:** Verify magnitude ≈ 1.0 after normalization
- [ ] **Self-similarity:** Test same image twice, should get ≈1.0 similarity
- [ ] **Similarity range:** Check max similarity across all pairs (if max < 0.90, threshold too high)
- [ ] **Dimension mismatch:** Ensure `embeddingDimension` constant matches actual model output
- [ ] **Model conversion:** Re-convert model using full CLIPModel (not CLIPVisionModel)
- [ ] **Image preprocessing:** Verify 224x224 size, RGB format, proper scaling

## Performance Characteristics

### Expected Performance (iPhone 12+, A14 chip)

| Operation | Time (per photo) | Notes |
|-----------|-----------------|-------|
| PHAsset fetch | <1ms | Memory-efficient enumeration |
| Image loading (224x224) | 10-50ms | Varies with iCloud/local |
| CoreML inference | 20-100ms | GPU acceleration, batch=1 |
| Embedding normalization | <1ms | Simple vector ops |
| Cosine similarity | <1ms | Accelerate vDSP_dotpr |
| **Total per photo** | **30-150ms** | **~7-30 photos/second** |

**For 1000 photos:**
- Sequential: 30-150 seconds
- Parallel (4 concurrent): 8-40 seconds

**Memory usage:**
- Model: ~350 MB
- Per embedding: 512 floats × 4 bytes = 2 KB
- 10,000 embeddings: ~20 MB
- **Total: <400 MB** for 10K photos

### Optimization Opportunities

1. **Batch inference:** CoreML supports batching, can process 4-8 images per inference call (4x speedup)
2. **Embedding cache:** Skip inference for previously scanned photos (indefinite speedup for re-scans)
3. **Similarity matrix computation:** Use vDSP matrix operations instead of nested loops
4. **Parallel image loading:** Load next image while processing current (pipeline parallelism)

## Common Integration Mistakes

### Mistake 1: Not Checking Model Output Dimension

**Symptom:** Code runs without errors but finds no duplicates
**Root cause:** Reading only first 512 of 768 dimensions
**Detection:**
```swift
let multiArray = result.featureValue.multiArrayValue
print("Actual dimension: \(multiArray.count)")  // Reveals 768
print("Expected dimension: \(embeddingDimension)")  // Shows 512
```

### Mistake 2: Using Wrong Model Output Name

**Symptom:** `featureValue(for: "output")` returns nil
**Root cause:** Output is named "embedding" not "output"
**Detection:** Print `model.modelDescription.outputDescriptionsByName.keys`

### Mistake 3: Forgetting to Normalize Before Caching

**Symptom:** Cached embeddings give different similarity scores
**Root cause:** Cached raw embeddings, normalized at comparison time inconsistently
**Detection:** Check cache entries for magnitude ≠ 1.0

### Mistake 4: Using Different Preprocessing in Python vs iOS

**Symptom:** Same image gives different embeddings in Python vs iOS
**Root cause:** Different crop/scale strategies
**Detection:** Extract same image in both, compare first 10 values

## Sources

**HIGH Confidence (Official Documentation):**
- [VNCoreMLRequest - Apple Developer](https://developer.apple.com/documentation/vision/vncoremlrequest)
- [VNCoreMLFeatureValueObservation - Apple Developer](https://developer.apple.com/documentation/vision/vncoremlfeaturevalueobservation)
- [featureName Property - Apple Developer](https://developer.apple.com/documentation/vision/vncoremlfeaturevalueobservation/featurename)
- [PHAsset - Apple Developer](https://developer.apple.com/documentation/photos/phasset)
- [CLIP Model Documentation - Hugging Face](https://huggingface.co/docs/transformers/model_doc/clip)
- [openai/clip-vit-base-patch32 - Hugging Face](https://huggingface.co/openai/clip-vit-base-patch32)

**MEDIUM Confidence (Community Sources, Verified):**
- [Last hidden state vs pooler output in CLIPVisionModel - Hugging Face Forums](https://discuss.huggingface.co/t/last-hidden-state-vs-pooler-output-in-clipvisionmodel/26281)
- [Apple's Vision Framework: Image Similarity Techniques - Medium](https://medium.com/@MWM.io/apples-vision-framework-exploring-advanced-image-similarity-techniques-f7bb7d008763)
- [Swift meets Photos framework and CoreML - Towards Data Science](https://towardsdatascience.com/swift-meets-photos-framework-and-coreml-tech-details-behind-a-smart-tidying-up-app-38e1d4b9e842/)
- [Confidence of Vision different from CoreML output - Apple Forums](https://developer.apple.com/forums/thread/712895)

**LOW Confidence (Informational Only):**
- [Deployment to Core ML - TuriCreate](https://apple.github.io/turicreate/docs/userguide/object_detection/export-coreml.html)
- [Image recognition with CoreML - HACARUS](https://hacarus.com/tech/ios-coreml-image-processing/)

## Next Steps

1. **CRITICAL:** Re-convert CoreML model to output 512-dim embeddings (include projection layer)
2. Update `EmbeddingService` to verify dimension matches model spec (fail fast on mismatch)
3. Add verification step: test self-similarity (same image → ~1.0 similarity)
4. Consider switching from VNCoreMLRequest to direct MLModel.prediction() for clarity
5. Add comprehensive logging at each pipeline stage for future debugging
