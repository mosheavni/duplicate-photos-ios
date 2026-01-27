# Testing Patterns

**Analysis Date:** 2026-01-27

## Test Framework

**Runner:**
- XCTest (Apple's native testing framework)
- Xcode 15+ (project configured with Swift 6.0)
- Config: `project.yml` defines test targets

**Assertion Library:**
- XCTest built-in assertions: `XCTAssertTrue`, `XCTAssertEqual`, `XCTAssertNil`, `XCTAssertThrowsError`

**Run Commands:**
```bash
# Run all tests from Xcode
Cmd + U

# Run unit tests from command line
xcodebuild test -scheme DuplicatePhotos -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests from command line
xcodebuild test -scheme DuplicatePhotos -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing DuplicatePhotosUITests

# Run specific test class
xcodebuild test -scheme DuplicatePhotos -only-testing DuplicatePhotosTests/TestClassName
```

## Test File Organization

**Location:**
- Unit tests: `DuplicatePhotosTests/` directory (currently empty)
- UI tests: `DuplicatePhotosUITests/` directory (currently empty)
- Co-located testing not used; separate test bundles per project.yml specification

**Naming:**
- Test targets follow pattern: `[AppName]Tests` and `[AppName]UITests`
- Test files not yet created; convention will follow: `[TestedClass]Tests.swift`
- Test methods will follow: `test[Scenario][ExpectedBehavior]()`

**Structure:**
```
DuplicatePhotosTests/
├── Services/
│   ├── EmbeddingServiceTests.swift      # Model loading, embedding extraction
│   ├── SimilarityServiceTests.swift     # Cosine similarity computation, grouping
│   └── CacheServiceTests.swift          # Cache persistence, retrieval
├── Models/
│   └── PhotoAssetTests.swift            # Model initialization, properties
└── ViewModels/
    └── ScanViewModelTests.swift         # State management, scan lifecycle

DuplicatePhotosUITests/
├── Flows/
│   ├── ScanFlowUITests.swift            # Navigation, scan progress UI
│   └── GroupDetailFlowUITests.swift     # Photo selection, deletion confirmation
└── Components/
    ├── GroupCardViewTests.swift         # Card rendering, thumbnail loading
    └── PhotoThumbnailViewTests.swift    # Selection UI, metadata display
```

## Test Structure

**Suite Organization:**

Pattern observed from architecture; expected test structure:
```swift
import XCTest
@testable import DuplicatePhotos

final class SimilarityServiceTests: XCTestCase {

    var sut: SimilarityService!  // System Under Test

    override func setUp() async throws {
        try await super.setUp()
        sut = SimilarityService()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // Async/await test methods
    func testCosineSimilarityWithIdenticalVectors() async throws {
        // Arrange
        let vector = [1.0, 0.0, 0.0] as [Float]

        // Act
        let result = sut.cosineSimilarity(vector, vector)

        // Assert
        XCTAssertEqual(result, 1.0, accuracy: 0.001)
    }

    func testFindSimilarPairsAboveThreshold() async throws {
        // Arrange
        let photos = [
            PhotoAsset(phAsset: mockAsset1, embedding: [1.0, 0.0]),
            PhotoAsset(phAsset: mockAsset2, embedding: [0.99, 0.01])
        ]

        // Act
        let pairs = await sut.findSimilarPairs(photos: photos, threshold: 0.90)

        // Assert
        XCTAssertEqual(pairs.count, 1)
        XCTAssertGreaterThan(pairs[0].2, 0.90)
    }
}
```

**Patterns:**
- Async test methods using `async throws` for testing async code
- Setup/Teardown: `override func setUp() async throws`, `override func tearDown() async throws`
- Assertion pattern: Arrange-Act-Assert (AAA) with clear comments
- System Under Test (sut) property for the object being tested

## Mocking

**Framework:**
- XCTest built-in OCMock capabilities (not explicitly used yet)
- Manual mock objects likely for dependency injection

**Patterns:**

Expected mocking approach for services with dependencies:
```swift
// Mock PhotoLibraryService
class MockPhotoLibraryService: PhotoLibraryService {
    var shouldFailAuthorization = false
    var mockPhotos: [PHAsset] = []

    override func requestAuthorization() async throws -> PHAuthorizationStatus {
        guard !shouldFailAuthorization else {
            throw PhotoLibraryError.accessDenied
        }
        return .authorized
    }

    override func fetchAllPhotos() async throws -> [PHAsset] {
        return mockPhotos
    }
}

// Mock CacheService
class MockCacheService: CacheService {
    var cachedEmbeddings: [String: CachedEmbedding] = [:]

    override func getEmbedding(for assetId: String) -> CachedEmbedding? {
        return cachedEmbeddings[assetId]
    }
}
```

**What to Mock:**
- External dependencies: `PhotoLibraryService`, `CacheService` (persistent I/O)
- iOS framework calls: PHPhotoLibrary authorization, PHImageManager image loading
- Time-dependent operations: Date calculations, timestamps
- Side effects: File I/O, CoreML model loading (for unit tests)

**What NOT to Mock:**
- Value types: `PhotoAsset`, `ScanSettings`, `CachedEmbedding` (use real instances)
- Pure computation: `cosineSimilarity` function (no side effects)
- SwiftUI view logic in isolation (test ViewModel instead)
- Framework structs: `PHAsset`, `UIImage` (mock factory patterns instead)

## Fixtures and Factories

**Test Data:**

Pattern for embedding fixtures (from Python reference compatibility):
```swift
// CLIP embedding fixture (512 dimensions)
let mockEmbedding: [Float] = Array(repeating: 0.0, count: 512)
    // OR load from reference data
    let mockEmbedding = loadEmbeddingFromFile("test_embedding_512d.json")

// PhotoAsset fixture factory
func makePhotoAsset(
    id: String = UUID().uuidString,
    embedding: [Float]? = nil,
    imageHash: String = "hash123"
) -> PhotoAsset {
    let mockAsset = PHAsset() // Mock or create minimal
    return PhotoAsset(phAsset: mockAsset, embedding: embedding, imageHash: imageHash)
}

// DuplicateGroup fixture
func makeDuplicateGroup(photoCount: Int = 2) -> DuplicateGroup {
    let photos = (0..<photoCount).map { i in
        makePhotoAsset(id: "photo_\(i)")
    }
    return DuplicateGroup(photos: photos, similarityScores: [:])
}

// ScanSettings fixture
let testSettings = ScanSettings(
    similarityThreshold: 0.90,
    useCaching: false  // Disable caching for deterministic tests
)
```

**Location:**
- `DuplicatePhotosTests/Fixtures/` directory (to be created)
- Shared test utilities: `DuplicatePhotosTests/TestHelpers.swift`
- Fixtures loaded from JSON if needed: `DuplicatePhotosTests/TestData/`

## Coverage

**Requirements:**
- No coverage threshold enforced in project configuration
- Target (per CLAUDE.md): >70% coverage for critical services

**View Coverage:**
```bash
# Generate coverage report in Xcode
xcodebuild test -scheme DuplicatePhotos -enableCodeCoverage YES

# View report in Xcode
# Product > Scheme > Edit Scheme > Test > Code Coverage
```

## Test Types

**Unit Tests:**
- **Scope:** Individual service methods, pure functions, models
- **Approach:** No external dependencies, fast execution (<100ms per test)
- **Examples:**
  - `SimilarityService`: cosineSimilarity correctness, findSimilarPairs thresholding
  - `CacheService`: save/load, serialization/deserialization
  - `PhotoAsset`: model initialization with optional fields
  - Embedding normalization: verify L2 norm = 1.0

**Integration Tests:**
- **Scope:** Service interactions, DuplicateDetector orchestration
- **Approach:** Use mock filesystem for cache, mock PHPhotoLibrary
- **Examples:**
  - Full scan pipeline: authorization → fetch → embed → similarity → grouping
  - Cache persistence: write embeddings → clear → load from disk
  - Error propagation: authorization denied → error in scan result

**E2E Tests:**
- **Framework:** XCUITest (Xcode UI testing)
- **Scope:** User-facing flows, navigation, UI state
- **Not yet implemented; planned for Phase 4 (Testing, Polish)**
- **Expected Coverage:**
  - Scan flow: tap Start → progress display → results navigation
  - Group detail: photo grid → selection → delete confirmation
  - Error handling: permission denied alert, network errors

## Common Patterns

**Async Testing:**

XCTest async support (iOS 13+):
```swift
// Test async function
func testExtractEmbeddingSucceeds() async throws {
    // Arrange
    let image = UIImage(systemName: "photo")!

    // Act
    let embedding = try await sut.extractEmbedding(from: image)

    // Assert
    XCTAssertEqual(embedding.count, 512)
    XCTAssertEqual(embedding.magnitude, 1.0, accuracy: 0.001) // Normalized
}

// Test async function with timeout
func testExtractEmbeddingTimeout() async throws {
    // Arrange
    let image = UIImage(systemName: "photo")!

    // Act & Assert
    await XCTAssertThrowsAsync(
        try await sut.extractEmbedding(from: image),
        throws: EmbeddingError.modelLoadFailed
    )
}
```

**Error Testing:**

```swift
// Test error thrown
func testPhotoLibraryAccessDeniedThrows() async throws {
    // Arrange
    let mockService = MockPhotoLibraryService(authStatus: .denied)

    // Act & Assert
    do {
        _ = try await mockService.requestAuthorization()
        XCTFail("Expected error not thrown")
    } catch PhotoLibraryError.accessDenied {
        // Expected path
    } catch {
        XCTFail("Wrong error type: \(error)")
    }
}

// Alternative: using XCTAssertThrowsError
func testModelLoadFailure() async throws {
    do {
        _ = try await EmbeddingService().extractEmbedding(from: UIImage())
        XCTFail("Should throw modelNotFound")
    } catch EmbeddingError.modelNotFound {
        // Expected
    }
}
```

**View Model Testing:**

```swift
// Test ViewModel state changes
@MainActor
func testScanProgressUpdates() async throws {
    // Arrange
    let viewModel = ScanViewModel()
    var progressValues: [Double] = []

    // Observe progress changes
    let subscription = viewModel.$progress.sink { progress in
        progressValues.append(progress)
    }

    // Act
    Task {
        await viewModel.startScan()
    }
    try await Task.sleep(nanoseconds: 100_000_000) // Wait for scan

    // Assert
    XCTAssertGreaterThan(progressValues.count, 1) // At least initial + final
    XCTAssertEqual(progressValues.last, 1.0) // Completes to 100%
}
```

---

*Testing analysis: 2026-01-27*
