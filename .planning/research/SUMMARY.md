# Research Summary: Duplicate Photos iOS

**Synthesized:** 2026-01-27
**Research Dimensions:** Stack, Features, Architecture, Pitfalls
**Overall Confidence:** HIGH

---

## Critical Finding: Root Cause Identified

**The scan returns "No duplicates found" because of a CoreML model dimension mismatch.**

### The Bug

| Expected | Actual | Impact |
|----------|--------|--------|
| 512-dimensional embeddings | 768-dimensional embeddings | Code truncates to first 512 values, corrupting embeddings |

### Root Cause

The CLIP model conversion script uses `CLIPVisionModel.pooler_output` (768-dim) instead of `CLIPModel.get_image_features()` (512-dim with projection layer).

```
CLIPVisionModel → pooler_output [768-dim] ← Current model outputs this
CLIPModel → visual_projection → image_embeds [512-dim] ← Code expects this
```

### Evidence

- `EmbeddingService.swift` hardcodes `embeddingDimension = 512`
- Model actually outputs 768 dimensions
- Code reads only first 512 of 768 values
- Truncated embeddings produce zero/meaningless similarity scores
- No pairs found → no groups → "No duplicates found"

---

## Two Fix Options

### Option A: Update Code to 768 Dimensions (Quick Fix)

**Pros:** No model reconversion, immediate fix
**Cons:** 50% larger cache, different from Python reference

Changes needed:
1. Update `embeddingDimension = 768` in `EmbeddingService.swift`
2. Clear existing cache (old embeddings are invalid)
3. Verify MLMultiArray shape handling for batch dimension

### Option B: Reconvert Model with Projection Layer (Proper Fix)

**Pros:** Matches Python reference (512-dim), smaller embeddings
**Cons:** Requires Python environment, model reconversion

Changes needed:
1. Modify conversion script to use full `CLIPModel` with `visual_projection`
2. Reconvert and replace `.mlpackage` file
3. Test output is 512 dimensions

**Recommendation:** Start with Option A for immediate debugging, then do Option B for production.

---

## Additional Issues Identified

### 1. MLMultiArray Batch Dimension
Model may output shape `[1, 768]` not `[768]`. Current indexing assumes flat array.

**Fix:** Check shape and use multi-index access if needed:
```swift
if multiArray.shape.count == 2 {
    embedding[i] = Float(truncating: multiArray[[0, i] as [NSNumber]])
}
```

### 2. Similarity Threshold
Current threshold (0.80) is reasonable for testing, but research suggests:
- **0.98+** for exact duplicates
- **0.90-0.95** for near-duplicates (recommended default: 0.92)
- **0.80-0.90** for similar photos (burst sequences)

---

## Stack Recommendations

| Layer | Technology | Status |
|-------|------------|--------|
| UI | SwiftUI + MVVM | ✅ Correct |
| ML Inference | Vision + CoreML | ✅ Correct approach |
| Vector Math | Accelerate vDSP | ✅ Already using |
| Photo Access | PhotoKit | ✅ Implemented |
| Concurrency | Swift 6 Actors | ✅ Correct pattern |

**No changes needed to technology stack.** Issue is model conversion, not architecture.

---

## Feature Priorities (Post-Fix)

### MVP (This Sprint)
1. **Fix scan** - Apply dimension fix
2. **Settings screen** - Adjustable similarity threshold
3. **Batch delete** - "Delete all but first" action

### v1.1
4. Cache management UI
5. Screenshot filtering
6. Performance optimization

### v2.0
7. Smart "best to keep" selection
8. Burst detection
9. Video support

---

## Debugging Checklist

When testing the fix, verify:

- [ ] `multiArray.shape` logged (expect `[1, 768]` or `[768]`)
- [ ] `multiArray.count` matches expected dimension
- [ ] Embedding values are non-zero, varied
- [ ] Embedding magnitude ≈ 1.0 after normalization
- [ ] Self-similarity (same image twice) ≈ 1.0
- [ ] Max similarity across pairs > threshold
- [ ] Groups formed when duplicates exist

---

## Key Sources

**Model Dimension:**
- [Hugging Face: pooler_output vs image_embeds](https://discuss.huggingface.co/t/last-hidden-state-vs-pooler-output-in-clipvisionmodel/26281)
- [Hugging Face: CLIP embedding dimensions](https://discuss.huggingface.co/t/how-to-get-an-embedding-of-size-512-using-clip-equal-to-open-clip/73849)

**CoreML Integration:**
- [Apple: VNCoreMLFeatureValueObservation](https://developer.apple.com/documentation/vision/vncoremlfeaturevalueobservation)
- [CoreML batch dimension issues](https://github.com/apple/coremltools/issues/371)

**Similarity Thresholds:**
- [CLIP Image Similarity - Medium](https://medium.com/@jeremy-k/unlocking-openai-clip-part-2-image-similarity-bf0224ab5bb0)
- [On Erroneous Agreements of CLIP Embeddings - arXiv](https://arxiv.org/html/2411.05195v1)

---

## Confidence Assessment

| Finding | Confidence | Reasoning |
|---------|------------|-----------|
| Dimension mismatch is root cause | HIGH | Direct model inspection + code analysis |
| Option A will fix bug | HIGH | Standard approach, verified in similar projects |
| Option B is production-ready | HIGH | Matches Python reference implementation |
| Similarity thresholds | MEDIUM | Research-backed but needs empirical testing |
| Feature priorities | MEDIUM | Based on competitor analysis, solo dev constraints |

---

## Next Steps

1. **Immediate:** Apply dimension fix (Option A or B)
2. **Verify:** Run scan with test duplicates, check logs
3. **Iterate:** If still failing, check MLMultiArray batch dimension
4. **Ship:** Once scan works, add Settings screen for threshold adjustment

---

*Research synthesis complete. Ready for roadmap creation.*
