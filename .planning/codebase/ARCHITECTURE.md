# Architecture

**Analysis Date:** 2026-01-27

## Pattern Overview

**Overall:** MVVM (Model-View-ViewModel) with actor-based services for concurrent safety

**Key Characteristics:**
- Separation of concerns across Models, ViewModels, Views, and Services
- Actor-based concurrency for thread-safe service operations
- Unidirectional data flow from Services → ViewModels → Views
- Observable patterns via `@Published` properties in ViewModels
- Async/await for all I/O operations and long-running tasks

## Layers

**Services Layer:**
- Purpose: Core business logic and platform integration
- Location: `DuplicatePhotos/Services/`
- Contains: Five actor-based services orchestrating the duplicate detection pipeline
- Depends on: Foundation, Photos, CoreML, Vision, Accelerate frameworks
- Used by: ViewModels and other services

**Models Layer:**
- Purpose: Data structures and configuration
- Location: `DuplicatePhotos/Models/`
- Contains: `PhotoAsset`, `DuplicateGroup`, `ScanSettings`, `CachedEmbedding`
- Depends on: Foundation, Photos frameworks
- Used by: Services, ViewModels, Views

**ViewModel Layer:**
- Purpose: UI state management and orchestration
- Location: `DuplicatePhotos/ViewModels/`
- Contains: `ScanViewModel` (observes service results, manages progress)
- Depends on: Models, Services
- Used by: SwiftUI Views via `@StateObject` and `@ObservedObject`

**View Layer:**
- Purpose: User interface and user interactions
- Location: `DuplicatePhotos/Views/`
- Contains: `ContentView`, `ScanView`, `DuplicateGroupsListView`, `GroupDetailView`, component views
- Depends on: ViewModels, Models, SwiftUI, Photos frameworks
- Used by: App entry point

**App Entry Point:**
- Purpose: Application bootstrap and scene setup
- Location: `DuplicatePhotos/App/DuplicatePhotosApp.swift`
- Contains: `@main` scene definition
- Depends on: SwiftUI, Views
- Used by: iOS runtime

## Data Flow

**Duplicate Detection Pipeline:**

1. User taps "Start Scan" → `ScanView` calls `ScanViewModel.startScan()`
2. `ScanViewModel` dispatches `DuplicateDetector.scanForDuplicates()`
3. `DuplicateDetector` orchestrates the full pipeline:
   - Requests photo library authorization via `PhotoLibraryService`
   - Fetches all photo assets via `PhotoLibraryService.fetchAllPhotos()`
   - For each asset:
     - Checks cache via `CacheService.getEmbedding()`
     - If not cached: loads image via `PhotoLibraryService.loadImage()` → extracts embedding via `EmbeddingService.extractEmbedding()` → saves to cache
   - Computes pairwise similarity via `SimilarityService.findSimilarPairs()` using normalized embeddings
   - Groups similar photos using DFS connected components algorithm
   - Returns sorted list of duplicate groups (largest first)
4. `ScanViewModel` receives groups, updates `@Published` properties
5. Views reactively update to display progress, then results
6. User selects photos for deletion via `GroupDetailView`
7. Deletion is processed via `PHPhotoLibrary.performChanges()` in `GroupDetailView`

**State Management:**

- Transient UI state (scanning, progress): managed by `ScanViewModel` via `@Published`
- Persistent embedding cache: managed by `CacheService` using file-based JSON persistence
- Photo library access: delegated to `PhotoLibraryService` (stateless)
- Results: `DuplicateGroup` instances flow from service → ViewModel → Views

## Key Abstractions

**DuplicateDetector (actor):**
- Purpose: Main orchestrator coordinating the entire detection pipeline
- Location: `DuplicatePhotos/Services/DuplicateDetector.swift`
- Pattern: Facade pattern - hides complexity of coordinating five sub-services
- Provides single entry point: `scanForDuplicates(settings:progress:)` returns `[DuplicateGroup]`
- Manages progress callbacks for UI updates

**PhotoLibraryService (actor):**
- Purpose: Safe access to Photos framework with authorization handling
- Location: `DuplicatePhotos/Services/PhotoLibraryService.swift`
- Pattern: Wrapper/adapter for PHPhotoLibrary
- Key operations: authorization checks, asset fetching, image loading, asset deletion

**EmbeddingService (actor):**
- Purpose: CoreML model inference for image embeddings
- Location: `DuplicatePhotos/Services/EmbeddingService.swift`
- Pattern: Lazy-loaded singleton model with initialization guard
- Responsibilities:
  - Lazy-loads CLIPVision.mlmodelc on first use
  - Preprocesses images via Vision framework
  - Normalizes output embeddings (L2 normalization)
  - Converts MLMultiArray to Swift array

**SimilarityService (actor):**
- Purpose: Vector similarity computations and grouping
- Location: `DuplicatePhotos/Services/SimilarityService.swift`
- Pattern: Algorithm provider using Accelerate framework primitives
- Key operations:
  - `cosineSimilarity()`: uses vDSP for high-performance dot product and magnitude
  - `findSimilarPairs()`: O(n²) comparison with threshold filtering
  - Connected components grouping via DFS

**CacheService (actor):**
- Purpose: Persistent embedding cache to avoid redundant model inference
- Location: `DuplicatePhotos/Services/CacheService.swift`
- Pattern: File-based JSON persistence with in-memory dictionary
- Stores: Asset ID → `CachedEmbedding` (embedding + imageHash + timestamp)
- Location: `~/.cache/DuplicatePhotos/embeddings_cache.json`

**PhotoAsset (struct):**
- Purpose: Wraps PHAsset with computed embedding and metadata
- Location: `DuplicatePhotos/Models/PhotoAsset.swift`
- Composable unit: PHAsset + embedding vector + image hash
- Identifiable via `PHAsset.localIdentifier`

**DuplicateGroup (struct):**
- Purpose: Represents one group of similar photos with metadata
- Location: `DuplicatePhotos/Models/DuplicateGroup.swift`
- Contains: photo array, pairwise similarity scores
- Sortable: by group size (largest first)

## Entry Points

**DuplicatePhotosApp:**
- Location: `DuplicatePhotos/App/DuplicatePhotosApp.swift`
- Triggers: Application launch
- Responsibilities: Creates WindowGroup, injects ContentView

**ContentView:**
- Location: `DuplicatePhotos/Views/ContentView.swift`
- Triggers: On app start
- Responsibilities: Home screen with navigation to ScanView

**ScanView (nested in ContentView):**
- Location: `DuplicatePhotos/Views/ContentView.swift` (lines 49-87)
- Triggers: User taps "Start Scan"
- Responsibilities:
  - Creates ScanViewModel
  - Conditionally displays: progress view → results list → empty state
  - Handles error alerts

**GroupDetailView:**
- Location: `DuplicatePhotos/Views/GroupDetailView.swift`
- Triggers: User taps a duplicate group card
- Responsibilities: Photo grid, selection, deletion with confirmation

## Error Handling

**Strategy:** Localized error types with async/throws pattern

**Patterns:**

- **PhotoLibraryService:**
  - Enum: `PhotoLibraryError` (accessDenied, accessRestricted, fetchFailed, imageLoadFailed)
  - Throws on authorization failure or fetch issues
  - Example: `try await photoLibrary.requestAuthorization()`

- **EmbeddingService:**
  - Enum: `EmbeddingError` (modelNotFound, modelLoadFailed, preprocessingFailed, predictionFailed)
  - Lazy-loads model with failure handling
  - Example: `try await embedding.extractEmbedding(from: image)`

- **ViewModel Error Handling:**
  - Catches service errors in try/catch block
  - Publishes error message via `@Published var errorMessage: String?`
  - Views display via alert binding

- **UI Error Display:**
  - `ScanView` shows alert when `errorMessage` is not nil
  - User can dismiss and retry

## Cross-Cutting Concerns

**Logging:**
- Approach: Unstructured print statements with emoji prefixes (debug/production logging needed)
- Examples: "🤖 Model loaded", "❌ Model is nil", "✅ Embedding extracted"
- Locations: All services include progress/diagnostic logging

**Validation:**
- Approach: Preconditions and guard statements
- Photo count validation: ignore assets with nil embeddings
- Similarity threshold: configurable via `ScanSettings.similarityThreshold` (default 0.85)
- Embedding dimension: hardcoded to 512 (CLIPVision output)

**Authentication:**
- Approach: PHPhotoLibrary authorization with status checking
- Flow: Check status → request if undetermined → throw if denied/restricted
- Fallback: Graceful error message to user
- Scopes: `.readWrite` for library access and deletion

**Concurrency:**
- Approach: Actor-based isolation with async/await
- All services are actors, preventing concurrent mutations
- Progress callbacks use `@Sendable` closure semantics
- ViewModels use `@MainActor` for UI updates

**Performance Optimization:**
- Image loading: Resized to 224×224 during embedding, thumbnails on demand
- Similarity computation: Uses Accelerate framework (vDSP) for SIMD operations
- Caching: Persistent JSON cache with lazy loading
- UI updates: Progressive via ProgressView during scan

---

*Architecture analysis: 2026-01-27*
