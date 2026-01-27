# Coding Conventions

**Analysis Date:** 2026-01-27

## Naming Patterns

**Files:**
- PascalCase for all Swift source files: `EmbeddingService.swift`, `PhotoAsset.swift`, `DuplicateGroup.swift`
- One public type per file (structs, classes, actors)
- Model files grouped in `Models/` directory: `PhotoAsset.swift`, `ScanSettings.swift`, `DuplicateGroup.swift`
- Service files grouped in `Services/` directory: `EmbeddingService.swift`, `SimilarityService.swift`, `CacheService.swift`
- View files grouped in `Views/` directory: `ContentView.swift`, `GroupDetailView.swift`, `DuplicateGroupsListView.swift`
- ViewModel files grouped in `ViewModels/` directory: `ScanViewModel.swift`

**Functions:**
- camelCase for all function names: `extractEmbedding`, `cosineSimilarity`, `findSimilarPairs`, `loadImage`
- Descriptive action verbs: `load`, `extract`, `compute`, `fetch`, `request`, `clear`, `save`, `persist`
- Private helper functions use underscore prefix: `_dfs`, `_normalizeEmbedding`, `_loadCache`
- Computed properties use noun phrases: `statusText`, `averageSimilarity`, `representative`

**Variables:**
- camelCase for instance variables and let bindings: `isScanning`, `currentPhoto`, `totalPhotos`, `duplicateGroups`
- Descriptive names avoid abbreviations: `viewModel` not `vm`, `assetIdentifier` not `assetId`
- Boolean prefixes: `isScanning`, `isDeleting`, `showError`, `useCaching`, `includeVideos`
- Collection names are plural: `similarPairs`, `duplicateGroups`, `thumbnails`
- Dictionary keys use camelCase: `assetIdentifier`, `imageHash`

**Types:**
- PascalCase for structs: `PhotoAsset`, `ScanSettings`, `CachedEmbedding`, `DuplicateGroup`
- PascalCase for enum cases: `modelNotFound`, `accessDenied`, `predictionFailed`
- PascalCase for protocol/actor names: `EmbeddingService`, `SimilarityService`, `PhotoLibraryService`

## Code Style

**Formatting:**
- No explicit formatting tool configured (SwiftLint/SwiftFormat not found in config)
- Manual formatting follows standard Swift style conventions
- 4-space indentation (default Xcode)
- Line length: typically <100 characters, no explicit limit enforced
- Brace style: Allman style (opening brace on same line for functions): `func loadImage() async throws -> UIImage {`

**Linting:**
- No SwiftLint or SwiftFormat configuration detected
- No pre-commit hooks for code quality
- Manual code review standards apply

## Import Organization

**Order:**
1. Foundation imports (always first): `import Foundation`, `import UIKit`
2. Framework imports in alphabetical order: `import Accelerate`, `import CoreML`, `import Photos`, `import SwiftUI`, `import Vision`
3. No internal module imports (monolithic app structure)

**Path Aliases:**
- No path aliases configured in project
- Direct relative imports not used; all imports are framework-based
- File paths accessed via Bundle: `Bundle.main.url(forResource: "CLIPVision", withExtension: "mlmodelc")`

## Error Handling

**Patterns:**
- Custom enum-based errors with descriptive cases: `enum EmbeddingError: Error`, `enum PhotoLibraryError: Error`
- Error cases: `modelNotFound`, `modelLoadFailed`, `preprocessingFailed`, `predictionFailed`, `accessDenied`, `accessRestricted`, `fetchFailed`, `imageLoadFailed`
- Errors propagated with `throws` and `async throws` for async operations
- Do-catch blocks with specific error type matching:
  ```swift
  do {
      let image = try await photoLibrary.loadImage(for: asset)
  } catch {
      errorMessage = "Scan failed: \(error.localizedDescription)"
  }
  ```
- Guard statements with early returns for validation:
  ```swift
  guard let cgImage = image.cgImage else {
      throw EmbeddingError.preprocessingFailed
  }
  ```

## Logging

**Framework:** console logging via `print()` statements

**Patterns:**
- Emoji-prefixed debug messages for visual distinction: `🤖 Model loaded successfully`, `❌ Model is nil`, `✅ Embedding extracted`
- Contextual information logged at each step: image dimensions, comparison counts, similarity scores
- Optional/error cases logged with warning emoji: `⚠️ Photo \(i) has no embedding`
- Progress milestones logged: `🔍 Finding similar pairs`, `📸 Total photos`, `🎯 Comparisons made`
- Silently handle non-critical failures: `try? fileManager.createDirectory` with no logging
- Cache loading failures logged with standard print: `print("Failed to load cache: \(error)")`

**Example from `EmbeddingService.swift`:**
```swift
print("🤖 Model loaded successfully")
print("📐 Image size: \(cgImage.width)x\(cgImage.height)")
print("✅ Embedding extracted, dimension: \(multiArray.count)")
print("✅ Embedding normalized, first 5 values: \(Array(normalized.prefix(5)))")
```

## Comments

**When to Comment:**
- Algorithm explanations for complex logic: Comments above DFS implementation in `DuplicateDetector.swift`
- Formula explanations: `// Formula: dot(a, b) / (norm(a) * norm(b))`
- High-level section markers for major code blocks: `// 1. Request photo library access`, `// 2. Fetch all photos`, `// 3. Extract embeddings`
- Caching strategy notes: `// Check cache first`, `// Extract new embedding`, `// Cache the embedding`
- No self-documenting code rule enforced; comments used moderately for clarity
- Inline comments rare; only for non-obvious logic

**JSDoc/TSDoc:**
- Swift documentation comments (///) used for public API functions
- Triple-slash doc comments at function level:
  ```swift
  /// Service for extracting embeddings from images using CoreML CLIP model
  actor EmbeddingService {
  ```
  ```swift
  /// Extract embedding from an image
  func extractEmbedding(from image: UIImage) async throws -> [Float] {
  ```
- Documentation includes parameter descriptions implicitly in function signature
- No explicit parameter documentation format (@param) observed
- Return type documentation: `/// Compute cosine similarity between two embedding vectors`

## Function Design

**Size:** Functions typically 5-40 lines; longer functions have clear multi-step structure with comments

**Parameters:**
- Single responsibility principle: functions accept minimal required parameters
- Default parameters used for optional configuration: `targetSize: CGSize = CGSize(width: 224, height: 224)`
- Callback/closure parameters come last: `progress: ProgressHandler? = nil`
- Type aliases for complex closures: `typealias ProgressHandler = @Sendable (Int, Int) -> Void`

**Return Values:**
- Async operations return via `async throws -> Type`
- Tuples used for multiple return values: `func getCacheStats() -> (count: Int, size: Int)`
- Optional returns for nullable results: `func getEmbedding(for assetId: String) -> CachedEmbedding?`
- Computed properties for derived values: `var count: Int { photos.count }`
- Early exits with guard and throw preferred over nested conditions

## Module Design

**Exports:**
- Structs and classes public by default (internal visibility not explicitly marked)
- Services are actors (isolated by Swift concurrency): `actor EmbeddingService`
- Private helper functions use `private` keyword: `private func normalizeEmbedding`
- Private instance variables marked with `private`: `private var model: VNCoreMLModel?`
- No explicit public/open modifiers used (defaults to internal in framework context)

**Barrel Files:**
- No barrel files or aggregator modules detected
- Direct imports from specific files: `from Services/EmbeddingService.swift`
- No re-exports observed

## Swift Concurrency Patterns

**Actors:**
- Services implemented as actors for thread-safety: `actor EmbeddingService`, `actor SimilarityService`, `actor CacheService`
- Isolated state prevents data races in concurrent environments
- Actor methods automatically protected from concurrent access

**Async/Await:**
- All long-running operations marked `async`: `func loadImage() async throws`, `func scanForDuplicates() async throws`
- Task-based callbacks for progress reporting: `Task { @MainActor [weak self] in ... }`
- MainActor annotations for UI updates: `@MainActor class ScanViewModel: ObservableObject`
- withCheckedContinuation for bridging callback-based APIs: `await withCheckedContinuation { continuation in ... }`

**MainActor:**
- ViewModel marked with `@MainActor` to ensure UI updates on main thread
- Explicit MainActor.run() for UI state changes from background tasks:
  ```swift
  await MainActor.run {
      thumbnails = loadedImages
  }
  ```

---

*Convention analysis: 2026-01-27*
