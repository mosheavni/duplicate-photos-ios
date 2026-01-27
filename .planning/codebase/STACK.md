# Technology Stack

**Analysis Date:** 2026-01-27

## Languages

**Primary:**
- Swift 6.0 - All application code, services, views, and models

## Runtime

**Environment:**
- iOS 17.0+ (deployment target)
- iPhone and iPad support (TARGETED_DEVICE_FAMILY: 1,2)

**Architecture:**
- Native iOS (using SwiftUI framework)
- No external runtime dependencies beyond iOS SDK

## Frameworks

**Core UI:**
- SwiftUI - All UI implementation (views, state management)
  - Located: `DuplicatePhotos/Views/*.swift`
  - Entry point: `DuplicatePhotos/App/DuplicatePhotosApp.swift`

**Machine Learning:**
- CoreML - CLIP Vision model inference
  - Import: `CoreML` in `DuplicatePhotos/Services/EmbeddingService.swift`
  - Model file: `CLIPVision.mlpackage` (compiled to `.mlmodelc`)
  - Model size: ~350MB (requires Git LFS)
  - Input: 224x224 RGB image
  - Output: 512-dimensional embedding vector

**Vision & Image Processing:**
- Vision framework - CoreML request handling and image preprocessing
  - Used in `DuplicatePhotos/Services/EmbeddingService.swift`
  - Handles image cropping, scaling, and VNCoreMLRequest execution

**Photo Library Access:**
- Photos framework - PHPhotoLibrary, PHAsset, PHImageManager
  - Used in `DuplicatePhotos/Services/PhotoLibraryService.swift`
  - Handles authorization, photo fetching, image loading, and deletion

**Performance & Vector Math:**
- Accelerate framework - SIMD operations for cosine similarity
  - Used in `DuplicatePhotos/Services/SimilarityService.swift`
  - Functions: `vDSP_dotpr` (dot product), `vDSP_svesq` (sum of squares)
  - Performs efficient vector operations on 512-dimensional embeddings

**Concurrency:**
- Swift Concurrency (async/await, actors) - Built-in to Swift 6.0
  - Actor pattern: `EmbeddingService`, `SimilarityService`, `PhotoLibraryService`, `CacheService`, `DuplicateDetector`
  - Enables thread-safe concurrent operations

**Standard Library:**
- Foundation - Data structures, file I/O, JSON encoding/decoding
- UIKit - UIImage handling and image utilities

## Testing Frameworks

**Unit Testing:**
- XCTest - Native iOS testing framework
  - Config: Defined in `project.yml` under `DuplicatePhotosTests` target
  - Run via: `cmd + U` or Xcode schemes

**UI Testing:**
- XCTest UI Testing - Native iOS UI testing
  - Config: Defined in `project.yml` under `DuplicatePhotosUITests` target

## Build System

**Build Tool:**
- Xcode (xcodebuild) - Native iOS build system
- XcodeGen - Project generation from `project.yml`
  - Config file: `/Users/Moshe.Avni/Repos/duplicate-photos-ios/project.yml`

**Project Structure:**
- Generated: `DuplicatePhotos.xcodeproj`
- Scheme: `DuplicatePhotos` with Debug/Release/Profile/Analyze/Archive configurations

## Package Management

**Dependency Management:**
- No external package manager (no CocoaPods, SPM, or Carthage)
- Pure native iOS SDK dependencies
- All functionality built with system frameworks

## Configuration

**Build Settings:**
- Swift Version: 6.0 (explicitly set in `project.yml` and project.pbxproj)
- iOS Deployment Target: 17.0
- Bundle ID: `com.mosheavni.DuplicatePhotos`
- Development Language: English
- Asset Catalog: `Assets.xcassets`

**Info.plist Configuration:**
- Located: `DuplicatePhotos/Info.plist`
- Key permissions declared:
  - `NSPhotoLibraryUsageDescription`: "We need access to your photos to detect duplicates"
  - `NSPhotoLibraryAddUsageDescription`: "We need access to modify your photo library to merge duplicates"
- Scene manifest: Supports multiple scenes
- Orientation: Portrait, Landscape Left/Right (iPhone and iPad)

**Code Signing:**
- Debug: Manual (CODE_SIGN_IDENTITY: "-")
- Release: Automatic
- Both require DEVELOPMENT_TEAM configuration

## Platform Requirements

**Development:**
- Xcode with Swift 6.0 compiler
- macOS 13+ (for development)
- Git LFS (for CLIPVision.mlpackage model file)

**Device Requirements:**
- iPhone 12+ (A14 chip minimum for CoreML inference performance)
- iPad with A14 or newer
- iOS 17.0 or later

**Memory & Performance:**
- Target scan rate: 1000 photos in <30 seconds
- Memory usage: <500MB for 10k photos
- UI scrolling: 60fps
- Embedding cache uses JSON (stored in app's caches directory)

## Data Storage

**Local Storage:**
- File-based JSON cache: `embeddings_cache.json`
  - Location: `~/Library/Caches/DuplicatePhotos/`
  - Stores: `CachedEmbedding` structs (asset ID, 512-dim embedding, image hash, timestamp)
  - Serialization: JSONEncoder/JSONDecoder

**Photo Data:**
- Accessed via Photos framework (PHPhotoLibrary)
- No direct database (Core Data or SQLite) currently implemented
- Embeddings are transient unless cached

## External Dependencies

**None** - This is a pure iOS native app with zero third-party dependencies. All functionality uses system frameworks (CoreML, Vision, Photos, Accelerate, SwiftUI, Foundation).

---

*Stack analysis: 2026-01-27*
