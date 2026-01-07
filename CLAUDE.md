# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Native iOS app for detecting and managing duplicate photos using on-device CoreML processing. Built with Swift/SwiftUI, following MVVM architecture.

**Current Status**: Phase 1 (Foundation) - 90% Complete. Xcode project created, core services implemented.

## Critical Work Rules

**REQUIRED: After completing ANY task, you MUST immediately update the documentation:**

1. Update the relevant epic file in `docs/epics/` to mark tasks as complete
2. Update `docs/PROJECT_TRACKER.md` with current progress
3. Check off completed items with `[x]` and add ✅ status markers
4. This is NOT optional - it must be done after every single task

## Project State

✅ Xcode project created (DuplicatePhotos.xcodeproj)
✅ Core services implemented (PhotoLibrary, Embedding, Similarity, Cache, DuplicateDetector)
✅ MVVM structure in place
⏳ Next: Convert CLIP model to CoreML

Next steps:

1. CLIP model must be converted to CoreML using `scripts/convert_clip_to_coreml.py`
2. Update EmbeddingService to use the converted model
3. Build complete UI for scanning and viewing results

## Key Commands

### Model Conversion

```bash
# Convert CLIP vision model to CoreML (prerequisite for app)
python3 scripts/convert_clip_to_coreml.py
```

### Building & Running (once Xcode project exists)

```bash
# Open project
open DuplicatePhotos.xcodeproj

# Build and run in Xcode: cmd + R
# Run tests: cmd + U
```

### Git LFS (for CoreML model files)

```bash
brew install git-lfs
git lfs install
git lfs track "*.mlmodel"
```

## Architecture

**Pattern**: MVVM (Model-View-ViewModel)

### Services Layer (Core Business Logic)

- **EmbeddingService**: Wraps CoreML CLIP model, extracts 512-dim embeddings
- **SimilarityService**: Cosine similarity computation using Accelerate framework
- **CacheService**: Persists embeddings (Core Data/SQLite) to avoid reprocessing
- **PhotoLibraryService**: PHPhotoLibrary access and image loading
- **DuplicateDetector**: Orchestrates entire scan pipeline

### Data Flow

1. PhotoLibraryService fetches PHAssets
2. EmbeddingService extracts embeddings (checks CacheService first)
3. SimilarityService computes pairwise cosine similarity
4. Connected components algorithm (DFS) groups similar photos
5. ViewModels expose results to SwiftUI views

### Key Algorithms (from Python reference)

**Cosine Similarity** (use Accelerate vDSP):

```swift
func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
    // dot(a, b) / (norm(a) * norm(b))
    // Use vDSP_dotpr and vDSP_svesq for performance
}
```

**Connected Components Grouping**:

- Build adjacency graph from similar pairs (threshold: 0.90)
- DFS traversal to find connected components
- Each component = one duplicate group

## Project Structure (Planned)

```
DuplicatePhotos/              # Main app target
├── App/                      # App entry point (@main)
├── Models/                   # PhotoAsset, DuplicateGroup, ScanSettings
├── ViewModels/               # ScanViewModel, GroupViewModel, SettingsViewModel
├── Views/                    # ScanView, DetailView, SettingsView, GroupsListView
├── Services/                 # Core services (listed above)
└── Resources/                # Assets.xcassets, CoreML models

DuplicatePhotosTests/         # Unit tests (target: >70% coverage)
DuplicatePhotosUITests/       # UI tests
scripts/                      # Python conversion scripts
docs/                         # Epic documentation
Reference/duplicate-images/   # Python reference (Git submodule)
```

## Important Implementation Details

### CoreML Model

- Input: 224x224 RGB image (preprocessed)
- Output: 512-dimensional embedding vector
- Model file: ~350MB (requires Git LFS)
- Deployment target: iOS 17+

### Photo Library Access

- Request authorization via PHPhotoLibrary
- Use PHImageManager for efficient loading (thumbnails → full size on demand)
- Handle permission denial gracefully

### Performance Requirements

- Scan 1000 photos in <30 seconds
- Memory usage <500MB for 10k photos
- 60fps UI scrolling
- Device support: iPhone 12+ (A14 chip minimum)

### Caching Strategy

```swift
struct CachedEmbedding {
    let assetIdentifier: String  // PHAsset.localIdentifier
    let embedding: [Float]       // 512 dimensions
    let imageHash: String        // For invalidation check
    let createdAt: Date
}
```

## Python Reference Mapping

Key Python files → Swift equivalents:

| Python File               | Swift File                           | Purpose                     |
| ------------------------- | ------------------------------------ | --------------------------- |
| `ml/feature_extractor.py` | `Services/EmbeddingService.swift`    | CLIP embedding extraction   |
| `ml/similarity_engine.py` | `Services/SimilarityService.swift`   | Cosine similarity, grouping |
| `ml/cache.py`             | `Services/CacheService.swift`        | Embedding persistence       |
| `core/detector.py`        | `Services/DuplicateDetector.swift`   | Main orchestrator           |
| `core/scanner.py`         | `Services/PhotoLibraryService.swift` | Photo discovery             |
| `config/defaults.py`      | `Models/ScanSettings.swift`          | Configuration               |

## Development Workflow

### Phase Progression

1. **Phase 1 (weeks 1-2)**: Setup, model conversion, core services
2. **Phase 2 (weeks 3-4)**: Detection pipeline, basic UI
3. **Phase 3 (weeks 5-6)**: Full UI with merge/delete
4. **Phase 4 (weeks 7-8)**: Testing, polish, TestFlight

### When Writing Services

- Port algorithms directly from Python reference (in `Reference/duplicate-images/`)
- Use Accelerate framework (vDSP) for vector operations
- Add async/await for I/O operations
- Include progress reporting via callbacks
- Support cancellation with Task.isCancelled

### When Writing Views

- Follow iOS design guidelines (inspired by native Photos app)
- Use LazyVGrid for photo grids
- Implement smooth animations with spring curves
- Support Dark Mode
- Add VoiceOver accessibility labels

## Configuration

### Info.plist Required Keys

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photos to detect duplicates</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to modify your photo library to merge duplicates</string>
```

### Build Settings

- Swift Language Version: 5.9+
- iOS Deployment Target: 17.0
- Enable Swift Concurrency
- Optimization Level: -O for Release builds

## Testing Strategy

### Unit Tests Priority

1. SimilarityService (cosine similarity correctness)
2. Connected components grouping algorithm
3. EmbeddingService (model loading, preprocessing)
4. CacheService (CRUD operations)

### Test Data

Use small sample images with known embeddings from Python reference for validation.

## Documentation

Comprehensive planning docs in `docs/epics/`:

- epic-1: Project setup checklist
- epic-2: CoreML conversion steps
- epic-3: Core services implementation
- epic-4: UI components
- epic-5: MVVM architecture
- epic-6: Testing strategy
- epic-7: Deployment process

Track progress in `docs/PROJECT_TRACKER.md`.
