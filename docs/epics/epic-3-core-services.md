# Epic 3: Core Services Layer 🔧

**Status**: ⏳ Pending
**Phase**: 1-2 - Foundation & Core Functionality
**Duration**: 1 week

---

## Overview
Build the core business logic services for photo library access, similarity detection, caching, and duplicate detection orchestration.

---

## Tasks

### Task 3.1: Photos Library Service

**File**: `DuplicatePhotos/Services/PhotoLibraryService.swift`

- [ ] Create PhotoLibraryService.swift
- [ ] Request photo library permissions (PHPhotoLibrary)
- [ ] Fetch all photos (PHAsset query)
- [ ] Load images efficiently (thumbnails → full size on demand)
- [ ] Implement delete with undo support
- [ ] Handle permission denied gracefully
- [ ] Add progress reporting

**Python Reference**: `src/duplicate_images/core/scanner.py`

---

### Task 3.2: Similarity Search Service

**File**: `DuplicatePhotos/Services/SimilarityService.swift`

- [ ] Create SimilarityService.swift
- [ ] Implement cosine similarity (with Accelerate framework)
  ```swift
  func computeCosineSimilarity(_ a: [Float], _ b: [Float]) -> Float
  ```
- [ ] Implement pairwise similarity search
  ```swift
  func findSimilarPairs(embeddings: [[Float]], threshold: Float) -> [(Int, Int, Float)]
  ```
- [ ] Implement connected components grouping (DFS)
  ```swift
  func groupDuplicates(pairs: [(Int, Int, Float)]) -> [[Int]]
  ```
- [ ] Add threshold parameter (default: 0.90)
- [ ] Optimize with vDSP for performance
- [ ] Write unit tests

**Python Reference**:
- `src/duplicate_images/ml/similarity_engine.py:145-180` - Cosine similarity
- `src/duplicate_images/ml/similarity_engine.py:183-225` - Connected components

---

### Task 3.3: Caching Service

**File**: `DuplicatePhotos/Services/CacheService.swift`

- [ ] Create CacheService.swift
- [ ] Design Core Data model or SQLite schema
  - assetIdentifier (String)
  - embedding ([Float] - 512 dims)
  - imageHash (String)
  - createdAt (Date)
- [ ] Implement cache operations
  - `getCachedEmbedding(for assetId: String) -> [Float]?`
  - `cacheEmbedding(_ embedding: [Float], for assetId: String)`
- [ ] Add cache invalidation (check modification date)
- [ ] Implement cache size limits
- [ ] Add cache statistics
- [ ] Write tests

**Python Reference**: `src/duplicate_images/ml/cache.py`

---

### Task 3.4: Duplicate Detection Orchestrator

**File**: `DuplicatePhotos/Services/DuplicateDetector.swift`

- [ ] Create DuplicateDetector.swift
- [ ] Implement main scan pipeline:
  1. Fetch all photos from library
  2. Check cache for existing embeddings
  3. Extract embeddings with CoreML (if not cached)
  4. Cache new embeddings
  5. Find similar pairs
  6. Group into duplicate clusters
- [ ] Add progress tracking (0.0 - 1.0)
- [ ] Add cancellation support (Task cancellation)
- [ ] Handle errors gracefully
- [ ] Add background task support (if needed)
- [ ] Write integration tests

**Python Reference**: `src/duplicate_images/core/detector.py`

---

## Definition of Done

- [ ] All 4 services created and tested
- [ ] Can access user's photo library
- [ ] Can compute similarity between embeddings
- [ ] Can cache embeddings persistently
- [ ] Can orchestrate full duplicate detection pipeline
- [ ] Unit tests passing for each service
- [ ] Integration test passing for full pipeline

---

## Dependencies

**Blocked By**:
- Epic 2 (CoreML Model) - needs EmbeddingService

---

## Performance Targets

- Scan 1000 photos in <60 seconds
- Similarity search: O(n²) acceptable for MVP (optimize later)
- Cache hit rate: >80% on subsequent scans
