# Codebase Concerns

**Analysis Date:** 2026-01-27

## Tech Debt

**Cache Implementation Missing Invalidation Strategy:**
- Issue: `CacheService.swift` stores embeddings with image hash but never validates invalidation. If photo is edited in Photos app, cached embedding becomes invalid without detection.
- Files: `DuplicatePhotos/Services/CacheService.swift` (lines 11-16), `DuplicatePhotos/Services/DuplicateDetector.swift` (line 52)
- Impact: Long-running cache can accumulate stale embeddings, degrading duplicate detection accuracy over time. Users expect cache to handle photo modifications.
- Fix approach: Implement PHAsset modification date checking. Compare `createdAt` in `CachedEmbedding` against `PHAsset.modificationDate` on lookup. Clear stale entries on cache load or during periodic maintenance.

**Duplicate Graph Construction Logic in Two Places:**
- Issue: Connected components DFS algorithm is implemented identically in `SimilarityService.groupSimilarPhotos()` (lines 103-131) and `DuplicateDetector.reconstructGroups()` (lines 103-138). DRY violation.
- Files: `DuplicatePhotos/Services/SimilarityService.swift`, `DuplicatePhotos/Services/DuplicateDetector.swift`
- Impact: Bug fixes or algorithm changes must be applied in two places. Current code in SimilarityService is incomplete (line 126 creates empty DuplicateGroup), making it unusable. Only DuplicateDetector version works correctly.
- Fix approach: Extract DFS algorithm to private helper function in `DuplicateDetector` or create new `GraphGroupingService`. Remove unused implementation from `SimilarityService`.

**Image Hash Calculation is Oversimplified:**
- Issue: Line 52 in `DuplicateDetector.swift` uses `asset.localIdentifier.hash.description` as image hash. This is not a real content hash—it's just the asset ID converted to string.
- Files: `DuplicatePhotos/Services/DuplicateDetector.swift` (line 52)
- Impact: Cannot detect if photo content changed (e.g., filter applied, rotation). Cache invalidation strategy (above) will not work as intended.
- Fix approach: Compute actual hash using `PHAssetResource` to read image data and calculate MD5 or SHA256. Add hash comparison to invalidation check.

**SimilarityService Not Used in Actual Pipeline:**
- Issue: `SimilarityService.findSimilarPairs()` and `groupSimilarPhotos()` are not called by `DuplicateDetector`. Pipeline directly implements similarity finding in `DuplicateDetector.reconstructGroups()`.
- Files: `DuplicatePhotos/Services/SimilarityService.swift` (lines 37-131), `DuplicatePhotos/Services/DuplicateDetector.swift` (lines 81-139)
- Impact: `SimilarityService` is dead code. `findSimilarPairs()` has expensive O(n²) comparison but is never invoked. Code duplication suggests incomplete refactoring.
- Fix approach: Remove dead code from `SimilarityService` or integrate it into the pipeline if needed for separation of concerns. Consolidate logic in one place.

## Memory & Performance Concerns

**O(n²) Comparison Complexity Not Optimized:**
- Issue: `SimilarityService.findSimilarPairs()` (lines 48-73) performs full nested loop over all photos. For 1000 photos: 499,500 comparisons. No batching, no spatial indexing.
- Files: `DuplicatePhotos/Services/SimilarityService.swift`, `DuplicatePhotos/Services/DuplicateDetector.swift`
- Current approach: Full matrix multiplication of embeddings
- Impact: Target is <30 seconds for 1000 photos. With CoreML overhead and I/O, O(n²) similarity computation becomes bottleneck. CLAUDE.md specifies requirement but implementation doesn't optimize for it.
- Improvement path: Implement approximate nearest neighbors (e.g., locality-sensitive hashing, KD-trees). Use batch processing with Accelerate's matrix operations instead of pair-wise. Consider GPU acceleration via Metal Performance Shaders for large libraries (10k+ photos).

**Cache File Growing Unbounded:**
- Issue: `CacheService.swift` loads entire cache into memory (line 75) and persists as single JSON file. No eviction, size limits, or cleanup mechanism.
- Files: `DuplicatePhotos/Services/CacheService.swift` (lines 82-91)
- Impact: Cache file grows indefinitely. For 10k photos at 2KB per embedding: 20MB file loaded on every app launch. After deletes, orphaned embeddings remain.
- Improvement path: Implement LRU eviction, size limit checks (warn at 50MB, clear at 100MB). Add cleanup on app launch to remove entries for deleted assets. Consider SQLite instead of JSON for better indexing and incremental loads.

**Thumbnail Loading Not Canceled:**
- Issue: `GroupCardView.loadThumbnails()` (lines 102-133) and `PhotoThumbnailView.loadThumbnail()` (lines 214-237) use `withCheckedContinuation` without cancellation. If user navigates away, image requests continue in background.
- Files: `DuplicatePhotos/Views/DuplicateGroupsListView.swift` (lines 102-133), `DuplicatePhotos/Views/GroupDetailView.swift` (lines 214-237)
- Impact: Wasted CPU/memory for off-screen image loads. Poor scroll performance when rapidly scrolling through large groups.
- Safe modification: Wrap in `Task` with `Task.isCancelled` checks. Use `PHImageManager` request ID tracking to cancel pending requests on view disappear.

## Known Bugs

**SimilarityService.groupSimilarPhotos() Creates Empty Groups:**
- Symptoms: Method returns `DuplicateGroup` with empty photos array (line 126)
- Files: `DuplicatePhotos/Services/SimilarityService.swift` (line 126)
- Trigger: Call `groupSimilarPhotos()` with any similar pairs
- Workaround: This function is dead code and not called. Use `DuplicateDetector.reconstructGroups()` instead, which correctly populates groups (line 128).

**Progress Callback Precision Loss:**
- Symptoms: Progress bar jumps in discrete chunks instead of smooth progression
- Files: `DuplicatePhotos/ViewModels/ScanViewModel.swift` (lines 34-39)
- Cause: Progress calculated as `Double(current) / Double(total)` at embedding extraction phase only. Similarity computation phase has no progress updates.
- Impact: UI appears frozen during similarity computation (significant for large libraries)
- Solution: Split progress into phases: 50% for embeddings, 50% for similarity computation. Add progress callback to `SimilarityService`.

## Security Considerations

**Photos Deleted Without Backup Prompt:**
- Risk: `GroupDetailView.deleteSelectedPhotos()` (lines 119-139) performs permanent deletion without cloud sync notification. User might expect Photos app backup to save deleted photos.
- Files: `DuplicatePhotos/Views/GroupDetailView.swift` (lines 119-139)
- Current mitigation: Confirmation dialog shows "This action cannot be undone"
- Recommendations: Add warning that Photos iCloud backup won't recover deleted items (if enabled). Consider batch delete retry on network failure.

**Photo Library Permissions Not Re-requested:**
- Risk: If user revokes photo library permission mid-scan, error occurs but app doesn't offer to re-request authorization.
- Files: `DuplicatePhotos/Services/PhotoLibraryService.swift` (lines 22-37), `DuplicatePhotos/Services/DuplicateDetector.swift` (line 26)
- Current mitigation: `requestAuthorization()` called at scan start
- Recommendations: Handle `PHPhotoDenied` error in `ScanViewModel` with UI prompt to open Settings. Implement graceful permission downgrade to `.limited` state.

**EmbeddingService Model Load Not Verified:**
- Risk: Model file integrity not checked. If CLIPVision.mlmodelc is corrupted or partially downloaded, silent failure with `predictionFailed` error.
- Files: `DuplicatePhotos/Services/EmbeddingService.swift` (lines 30-35)
- Current mitigation: File existence check only
- Recommendations: Verify model checksum after bundle copy. Add retry logic with exponential backoff for network-downloaded models.

## Performance Bottlenecks

**Sequential Embedding Extraction:**
- Problem: Photos processed one-by-one in `DuplicateDetector.scanForDuplicates()` (lines 35-72). No batch processing or parallel image loading.
- Files: `DuplicatePhotos/Services/DuplicateDetector.swift`
- Cause: Awaiting each embedding sequentially instead of batching
- Improvement path: Implement batch processing (e.g., 5-10 photos concurrently) using `async let` or `TaskGroup`. Profile to find optimal batch size.

**CoreML Model Load on First Scan:**
- Problem: EmbeddingService loads 350MB CoreML model synchronously on first `extractEmbedding()` call, blocking UI briefly.
- Files: `DuplicatePhotos/Services/EmbeddingService.swift` (lines 27-37)
- Cause: Lazy loading in `ensureModelLoaded()`
- Improvement path: Pre-load model on app launch or background thread. Show loading indicator if model not ready.

**PHImageManager Synchronous Options:**
- Problem: `PHImageRequestOptions` in `PhotoLibraryService.loadImage()` (line 66) uses `deliveryMode = .highQualityFormat` with `isNetworkAccessAllowed = true`. Can trigger iCloud download for large libraries.
- Files: `DuplicatePhotos/Services/PhotoLibraryService.swift` (lines 63-85)
- Improvement path: Use `.fastFormat` for scanning (faster CPU). Only fetch high quality if user views full resolution. Cache thumbnail size (224x224) for embedding extraction.

## Fragile Areas

**DuplicateDetector Tight Coupling to Services:**
- Files: `DuplicatePhotos/Services/DuplicateDetector.swift` (lines 13-16)
- Why fragile: Detector instantiates all services directly. Cannot mock for testing. Adding new service requires refactoring.
- Safe modification: Inject services via constructor or dependency injection container.
- Test coverage: No unit tests exist (`DuplicatePhotosTests/` is empty)

**ScanViewModel Weak Self Capture:**
- Files: `DuplicatePhotos/ViewModels/ScanViewModel.swift` (line 35)
- Why fragile: `[weak self]` in Task closure means view can deallocate mid-scan, leaving progress callback orphaned. No completion handler on scan finish.
- Safe modification: Use `[self]` and ensure ScanViewModel lifecycle matches scan task. Or add explicit cancellation token.
- Test coverage: No tests for progress updates or error handling

**View Thumbnail Loading Race Conditions:**
- Files: `DuplicatePhotos/Views/DuplicateGroupsListView.swift`, `DuplicatePhotos/Views/GroupDetailView.swift`
- Why fragile: `.task { await loadThumbnails() }` can be called multiple times if view reappears. No deduplication of in-flight requests.
- Safe modification: Use `AsyncImage` or implement request deduplication. Add loading state to prevent duplicate calls.
- Test coverage: No UI tests for scroll performance or thumbnail loading

**No Error Recovery in Cache Service:**
- Files: `DuplicatePhotos/Services/CacheService.swift` (lines 72-78, 82-91)
- Why fragile: Silent failure if cache file is corrupted (lines 77-78: `print("Failed...")` but no recovery). Persists always succeeds even if disk is full.
- Safe modification: Check disk space before writing. Implement cache rollback or corruption recovery (fallback to empty cache).
- Test coverage: No unit tests for cache I/O failures

## Scaling Limits

**10k+ Photo Library Memory Constraints:**
- Current capacity: Up to ~5000 photos before hitting memory ceiling (based on 512-dim float embeddings = 2KB per photo)
- Limit: RAM exhaustion when holding all embeddings in `photoAssets` array (line 33 of DuplicateDetector)
- Scaling path: Stream processing instead of all-in-memory. Process chunks of 500-1000 photos at a time. Persist intermediate results to cache.

**Single-Threaded Similarity Computation:**
- Current capacity: 30-second target for 1000 photos
- Limit: Exceeds target with larger libraries (estimated 2+ minutes for 5000 photos)
- Scaling path: GPU acceleration via Metal Performance Shaders. Use SIMD/vDSP more aggressively. Consider approximate nearest neighbors.

## Dependencies at Risk

**CoreML Model Not in Repository:**
- Risk: CLIPVision.mlpackage is Git LFS tracked but requires manual conversion. If conversion script breaks, no fallback model.
- Files: `DuplicatePhotos/Resources/CLIPVision.mlpackage/` (Git LFS pointer)
- Impact: New developers cannot build without running Python conversion script
- Migration plan: Pre-build and commit quantized model for development. Keep full precision version in LFS. Add CI step to validate model loads.

## Missing Critical Features

**No Error Recovery UI for Failed Scans:**
- Problem: If scan fails midway (e.g., photo permission denied), error shown but no resume option
- Files: `DuplicatePhotos/ViewModels/ScanViewModel.swift` (lines 43-45), `DuplicatePhotos/Views/ContentView.swift` (lines 74-85)
- Blocks: Users with large libraries forced to restart scan
- Solution: Implement checkpoint-based scanning. Save progress state. Allow resume from last checkpoint.

**No Settings Screen Implementation:**
- Problem: `ScanSettings.swift` defines threshold, but no UI to adjust it. Users stuck with hardcoded defaults.
- Files: `DuplicatePhotos/Models/ScanSettings.swift`
- Blocks: Advanced users can't tune similarity threshold for their use case
- Solution: Create `SettingsView.swift` with threshold slider (0.70-0.95). Persist to UserDefaults.

**No Batch Delete Operation:**
- Problem: `GroupDetailView` can only delete from single group. Users with 100+ duplicate groups cannot bulk-clean without visiting each group.
- Files: `DuplicatePhotos/Views/GroupDetailView.swift` (lines 113-139)
- Blocks: Large-scale photo library cleanup is tedious
- Solution: Add "Select Multiple Groups" mode. Implement batch delete with single confirmation.

## Test Coverage Gaps

**No Tests for Core Similarity Algorithm:**
- What's not tested: Cosine similarity correctness, edge cases (zero vectors, identical vectors)
- Files: `DuplicatePhotos/Services/SimilarityService.swift` (lines 15-34)
- Risk: Numerical errors in similarity computation not caught (e.g., division by zero, NaN propagation)
- Priority: High - Correctness of core algorithm is critical

**No Tests for Cache Invalidation:**
- What's not tested: Cache hit/miss, expiration, corruption recovery
- Files: `DuplicatePhotos/Services/CacheService.swift`
- Risk: Cache bugs cause silent degradation (stale embeddings not detected)
- Priority: High - Cache is performance-critical path

**No Tests for DuplicateDetector Pipeline:**
- What's not tested: End-to-end scan with mock data, progress callback, error propagation
- Files: `DuplicatePhotos/Services/DuplicateDetector.swift`
- Risk: Pipeline integration bugs found only in production
- Priority: High - Orchestrator is central to app functionality

**No Tests for View State:**
- What's not tested: ScanViewModel progress updates, error display, state transitions
- Files: `DuplicatePhotos/ViewModels/ScanViewModel.swift`
- Risk: UI bugs (missing updates, incorrect state) not caught until manual testing
- Priority: Medium - Affects UX but not functionality

**Empty Test Targets:**
- Files: `DuplicatePhotosTests/` (empty), `DuplicatePhotosUITests/` (empty)
- Current coverage: 0%
- Target: >70% per CLAUDE.md
- Action: Implement tests for test-priority items above

---

*Concerns audit: 2026-01-27*
