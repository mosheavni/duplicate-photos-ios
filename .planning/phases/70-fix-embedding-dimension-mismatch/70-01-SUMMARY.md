# Phase 70-01 Summary: Fix Embedding Dimension Mismatch

**Status:** COMPLETED
**Date:** 2026-01-27

## Objective

Fix the scan returning "No duplicates found" due to embedding extraction issues.

## Root Cause Analysis

The original hypothesis (512 vs 768 dimension mismatch) was partially correct, but investigation revealed **multiple compounding issues**:

1. **Dimension mismatch**: Model outputs 768 dimensions, code expected 512
2. **Float16 data type**: Model outputs Float16, Swift wasn't converting correctly
3. **GPU backend failure**: Simulator's MPSGraph backend silently fails, returning zeros

## Changes Made

### 1. EmbeddingService.swift
- Changed `embeddingDimension` from 512 to 768
- Added **CPU-only inference** (`config.computeUnits = .cpuOnly`) to bypass broken MPSGraph on simulator
- Added manual Float16→Float32 bit conversion using IEEE 754 half-precision math
- Simplified code by removing Vision framework complexity (direct VNCoreMLRequest)

### 2. CacheService.swift
- Added `cacheVersion = 4` for cache invalidation
- Added `ensureCacheValid()` method
- Added `getCurrentCacheVersion()` and `getExpectedEmbeddingDimension()` methods

### 3. DuplicateDetector.swift
- Force clears cache at scan start during debugging phase
- Calls `cache.clearCache()` to ensure fresh embeddings

### 4. ScanSettings.swift
- Updated default `similarityThreshold` from 0.80 to 0.92

## Key Discovery

The **critical fix** was forcing CPU-only inference:
```swift
let config = MLModelConfiguration()
config.computeUnits = .cpuOnly
mlModel = try MLModel(contentsOf: modelURL, configuration: config)
```

Without this, the simulator's Espresso/MPSGraph backend silently fails:
```
E5RT: Espresso exception: "Invalid state": MpsGraph backend validation on incompatible OS
```

The model loads successfully but returns all-zero embeddings.

## Verification

- Scan with 9 photos completed successfully
- Duplicate groups detected
- Non-zero embedding magnitudes observed
- Similarity scores calculated correctly

## Files Modified

| File | Changes |
|------|---------|
| `EmbeddingService.swift` | 768-dim, CPU-only, Float16 conversion |
| `CacheService.swift` | Version tracking, validation methods |
| `DuplicateDetector.swift` | Force cache clear |
| `ScanSettings.swift` | Threshold 0.92 |

## Lessons Learned

1. **Simulator GPU limitations**: CoreML models may silently fail on simulator when using Metal/MPSGraph backends
2. **Float16 handling**: Swift's MLMultiArray subscript accessor doesn't always handle Float16 correctly - manual bit conversion may be needed
3. **Debug incrementally**: Adding diagnostic logging (raw bytes, magnitude) was essential for finding the true root cause

## Next Steps

- Phase 71: Can proceed with UI improvements
- Consider: Make CPU-only a debug/simulator-only flag for production builds
