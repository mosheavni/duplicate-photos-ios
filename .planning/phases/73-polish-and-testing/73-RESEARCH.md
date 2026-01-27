# Phase 73: Polish and Testing - Research

**Researched:** 2026-01-27
**Domain:** iOS Unit Testing, SwiftUI Empty States, Permission Handling
**Confidence:** HIGH

## Summary

This phase focuses on making the app ready for personal use testing by adding unit tests for core algorithms, improving empty state UX, and handling permission edge cases. The research covers:

1. **Unit Testing Stack**: XCTest remains the standard for this project since the app already has XCTest targets configured. Swift Testing (new in 2024) is an option but lacks UI/performance testing and has fewer resources.

2. **Algorithm Testing**: The SimilarityService contains two critical algorithms - cosine similarity (using Accelerate/vDSP) and connected components grouping (DFS-based). Both require careful test design with known test vectors and edge cases.

3. **Empty State UX**: SwiftUI's `ContentUnavailableView` (iOS 17+) is the standard pattern for empty states. The app already has an `EmptyScanView` that should be enhanced with this native component.

4. **Permission Handling**: PHPhotoLibrary authorization has multiple states (.denied, .restricted, .limited, .authorized). Each requires distinct UX treatment with clear messaging and recovery paths.

**Primary recommendation:** Use XCTest with async/await support for testing the actor-based SimilarityService, enhance empty states with ContentUnavailableView, and implement a permission state machine with clear user guidance.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| XCTest | Built-in | Unit testing framework | Already configured in project, mature ecosystem, handles async/await |
| SwiftUI ContentUnavailableView | iOS 17+ | Empty state UI | Native, consistent with system apps, auto-localized |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Swift Testing | Xcode 16+ | Modern testing macros | New projects, but lacks UI testing support |
| Accelerate | Built-in | Vector math (used by SimilarityService) | Test verification of vDSP calculations |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| XCTest | Swift Testing | Swift Testing is newer with better syntax (@Test, #expect) but lacks performance/UI testing, fewer community resources |
| Custom empty view | ContentUnavailableView | Custom gives more control but loses native consistency and localization |

## Architecture Patterns

### Recommended Test Structure
```
DuplicatePhotosTests/
├── Services/
│   ├── SimilarityServiceTests.swift    # Core algorithm tests
│   └── PhotoLibraryServiceTests.swift  # Permission state tests (if needed)
├── Helpers/
│   └── TestVectors.swift               # Known test embeddings
└── Extensions/
    └── XCTestCase+Async.swift          # Async testing helpers (if needed)
```

### Pattern 1: Testing Actors with Async XCTest
**What:** Swift actors require await to access methods; XCTest supports async test methods directly.
**When to use:** Testing SimilarityService (which is an actor)
**Example:**
```swift
// Source: https://www.avanderlee.com/concurrency/unit-testing-async-await/
final class SimilarityServiceTests: XCTestCase {
    var sut: SimilarityService!

    override func setUp() {
        super.setUp()
        sut = SimilarityService()
    }

    func testCosineSimilarity_identicalVectors_returnsOne() async {
        let vector = [Float](repeating: 1.0, count: 512)
        let result = await sut.cosineSimilarity(vector, vector)
        XCTAssertEqual(result, 1.0, accuracy: 0.0001)
    }
}
```

### Pattern 2: Floating Point Comparison with Accuracy
**What:** Float comparisons need accuracy bounds due to IEEE 754 precision limits.
**When to use:** All cosine similarity assertions
**Example:**
```swift
// Source: Apple XCTest documentation
let epsilon: Float = 0.0001
XCTAssertEqual(similarity, expectedValue, accuracy: epsilon)

// For near-zero comparisons
XCTAssertEqual(similarity, 0.0, accuracy: epsilon, "Orthogonal vectors should have ~0 similarity")
```

### Pattern 3: ContentUnavailableView for Empty States
**What:** System-provided view for empty content states with consistent styling.
**When to use:** Empty scan results, permission denied states
**Example:**
```swift
// Source: https://www.avanderlee.com/swiftui/contentunavailableview-handling-empty-states/
ContentUnavailableView {
    Label("No Duplicates Found", systemImage: "checkmark.circle")
} description: {
    Text("Your photo library looks clean!")
} actions: {
    Button("Scan Again") {
        // trigger rescan
    }
}
```

### Pattern 4: Permission State Machine
**What:** Handle all PHAuthorizationStatus cases with distinct UI.
**When to use:** PhotoLibraryService authorization flow
**Example:**
```swift
enum PermissionState {
    case notDetermined
    case authorized
    case limited
    case denied
    case restricted
}

// Map to user-facing UI
switch permissionState {
case .notDetermined:
    // Show request button
case .denied:
    // Show ContentUnavailableView with Settings button
case .restricted:
    // Show explanation (parental controls, MDM)
case .limited, .authorized:
    // Proceed with scan
}
```

### Anti-Patterns to Avoid
- **Testing private methods directly:** Don't make methods public just for testing; test through public API
- **Hardcoded test vectors without meaning:** Always document why a test vector should produce a specific result
- **Ignoring actor isolation:** Don't use nonisolated(unsafe) to bypass actor safety in tests
- **Using wait(for:) with async code:** Use `await fulfillment(of:)` instead to avoid deadlocks

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Empty state UI | Custom VStack with icon/text | ContentUnavailableView | Auto-localized, platform-consistent, accessibility built-in |
| Floating point comparison | `a == b` | `XCTAssertEqual(a, b, accuracy:)` | IEEE 754 precision issues |
| Async test waiting | Custom RunLoop spinning | XCTest async support / `await fulfillment(of:)` | Deadlock prevention, proper timeout handling |
| Permission denied UI | Custom alert | ContentUnavailableView + Settings deeplink | Standard iOS pattern users recognize |

**Key insight:** Apple provides standard components for common UX patterns. Using them ensures consistency with system apps and benefits from built-in accessibility and localization.

## Common Pitfalls

### Pitfall 1: Testing Actors Without Await
**What goes wrong:** Compiler error or using unsafe workarounds that break actor isolation.
**Why it happens:** Forgetting that actor methods require async context.
**How to avoid:** Mark test methods as `async` and use `await` for all actor method calls.
**Warning signs:** Compiler errors about actor isolation, use of `nonisolated(unsafe)`.

### Pitfall 2: Comparing Floats with ==
**What goes wrong:** Tests fail intermittently even with correct implementations.
**Why it happens:** IEEE 754 floating point cannot represent all decimal values exactly.
**How to avoid:** Always use `XCTAssertEqual(a, b, accuracy: epsilon)` for Float/Double.
**Warning signs:** Flaky tests, "expected 1.0 but got 0.9999999" failures.

### Pitfall 3: Connected Components Edge Cases
**What goes wrong:** Missing groups or incorrect grouping with single nodes or disconnected graphs.
**Why it happens:** Algorithm assumes all nodes are in graph, doesn't handle isolated vertices.
**How to avoid:** Test with: empty input, single pair, chain of pairs, disjoint clusters, single-node "groups".
**Warning signs:** Off-by-one in group count, groups with 1 element.

### Pitfall 4: Permission State Not Refreshing
**What goes wrong:** User grants permission in Settings but app still shows denied state.
**Why it happens:** Not re-checking authorization status when app returns to foreground.
**How to avoid:** Check authorization in `sceneDidBecomeActive` or use `.onReceive(NotificationCenter.publisher)`.
**Warning signs:** User reports needing to force-quit app after granting permission.

### Pitfall 5: Empty State Flicker
**What goes wrong:** Empty state briefly shows before results appear.
**Why it happens:** View renders before async operation completes.
**How to avoid:** Use loading state, only show empty after scan completes with 0 results.
**Warning signs:** Flash of "No Duplicates" then results appear.

## Code Examples

### Testing Cosine Similarity
```swift
// Source: Derived from mathematical properties
final class SimilarityServiceTests: XCTestCase {
    var sut: SimilarityService!
    let epsilon: Float = 0.0001

    override func setUp() {
        super.setUp()
        sut = SimilarityService()
    }

    // Test: Identical vectors have similarity 1.0
    func testCosineSimilarity_identicalVectors() async {
        let vector: [Float] = [1.0, 2.0, 3.0, 4.0, 5.0]
        let result = await sut.cosineSimilarity(vector, vector)
        XCTAssertEqual(result, 1.0, accuracy: epsilon)
    }

    // Test: Orthogonal vectors have similarity 0.0
    func testCosineSimilarity_orthogonalVectors() async {
        let a: [Float] = [1.0, 0.0, 0.0]
        let b: [Float] = [0.0, 1.0, 0.0]
        let result = await sut.cosineSimilarity(a, b)
        XCTAssertEqual(result, 0.0, accuracy: epsilon)
    }

    // Test: Opposite vectors have similarity -1.0
    func testCosineSimilarity_oppositeVectors() async {
        let a: [Float] = [1.0, 2.0, 3.0]
        let b: [Float] = [-1.0, -2.0, -3.0]
        let result = await sut.cosineSimilarity(a, b)
        XCTAssertEqual(result, -1.0, accuracy: epsilon)
    }

    // Test: Different length vectors return 0.0 (error handling)
    func testCosineSimilarity_differentLengths() async {
        let a: [Float] = [1.0, 2.0]
        let b: [Float] = [1.0, 2.0, 3.0]
        let result = await sut.cosineSimilarity(a, b)
        XCTAssertEqual(result, 0.0)
    }

    // Test: Zero vector returns 0.0 (avoid division by zero)
    func testCosineSimilarity_zeroVector() async {
        let a: [Float] = [1.0, 2.0, 3.0]
        let zero: [Float] = [0.0, 0.0, 0.0]
        let result = await sut.cosineSimilarity(a, zero)
        XCTAssertEqual(result, 0.0)
    }

    // Test: Known similarity value (calculated manually/externally)
    func testCosineSimilarity_knownValue() async {
        // cos(theta) between [1,0] and [1,1] = 1/sqrt(2) ≈ 0.7071
        let a: [Float] = [1.0, 0.0]
        let b: [Float] = [1.0, 1.0]
        let expected: Float = 1.0 / sqrt(2.0)  // ≈ 0.7071
        let result = await sut.cosineSimilarity(a, b)
        XCTAssertEqual(result, expected, accuracy: epsilon)
    }
}
```

### Testing Connected Components Grouping
```swift
// Note: Requires mock PhotoAsset or test helper
final class GroupingTests: XCTestCase {
    var sut: SimilarityService!

    override func setUp() {
        super.setUp()
        sut = SimilarityService()
    }

    // Test: Empty pairs returns empty groups
    func testGroupSimilarPhotos_emptyInput() {
        let pairs: [(PhotoAsset, PhotoAsset, Float)] = []
        let groups = sut.groupSimilarPhotos(pairs: pairs)
        XCTAssertTrue(groups.isEmpty)
    }

    // Test: Single pair creates one group
    func testGroupSimilarPhotos_singlePair() {
        // Create two test photos with same embedding
        let photo1 = makeTestPhoto(id: "1")
        let photo2 = makeTestPhoto(id: "2")
        let pairs = [(photo1, photo2, Float(0.95))]

        let groups = sut.groupSimilarPhotos(pairs: pairs)
        XCTAssertEqual(groups.count, 1)
    }

    // Test: Chain A-B, B-C creates one group {A,B,C}
    func testGroupSimilarPhotos_transitiveChain() {
        let photo1 = makeTestPhoto(id: "1")
        let photo2 = makeTestPhoto(id: "2")
        let photo3 = makeTestPhoto(id: "3")
        let pairs = [
            (photo1, photo2, Float(0.95)),
            (photo2, photo3, Float(0.92))
        ]

        let groups = sut.groupSimilarPhotos(pairs: pairs)
        XCTAssertEqual(groups.count, 1, "Chain should form single connected component")
    }

    // Test: Disjoint pairs create separate groups
    func testGroupSimilarPhotos_disjointPairs() {
        let photo1 = makeTestPhoto(id: "1")
        let photo2 = makeTestPhoto(id: "2")
        let photo3 = makeTestPhoto(id: "3")
        let photo4 = makeTestPhoto(id: "4")
        let pairs = [
            (photo1, photo2, Float(0.95)),
            (photo3, photo4, Float(0.93))
        ]

        let groups = sut.groupSimilarPhotos(pairs: pairs)
        XCTAssertEqual(groups.count, 2, "Disjoint pairs should form separate groups")
    }

    // Helper to create test photos (would need mock PHAsset)
    private func makeTestPhoto(id: String) -> PhotoAsset {
        // Implementation depends on how PhotoAsset can be mocked
    }
}
```

### ContentUnavailableView Empty State
```swift
// Source: https://www.hackingwithswift.com/books/ios-swiftui/showing-empty-states-with-contentunavailableview
struct EmptyScanResultView: View {
    let onRescan: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Duplicates Found", systemImage: "checkmark.circle")
        } description: {
            Text("Your photo library looks clean! All your photos appear to be unique.")
        } actions: {
            Button(action: onRescan) {
                Text("Scan Again")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
```

### Permission Denied State
```swift
// Source: https://swiftsenpai.com/development/photo-library-permission/
struct PermissionDeniedView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Photo Access Required", systemImage: "photo.badge.exclamationmark")
        } description: {
            Text("Please allow access to your photos in Settings to scan for duplicates.")
        } actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| XCTest only | Swift Testing available | WWDC 2024 | New @Test macro, #expect assertions, but XCTest still needed for UI tests |
| Custom empty views | ContentUnavailableView | iOS 17 (2023) | Standard, accessible empty states |
| wait(for: expectations) | await fulfillment(of:) | Xcode 14.3 | Prevents deadlocks in async tests |
| ObservableObject | @Observable | iOS 17 (2023) | Simpler state management (already used) |

**Deprecated/outdated:**
- `wait(for:timeout:)` in async context: Causes deadlocks, use `await fulfillment(of:)` instead
- Custom empty state VStacks: ContentUnavailableView is the standard since iOS 17

## Open Questions

1. **PhotoAsset Mocking**
   - What we know: PhotoAsset wraps PHAsset which is not easily mockable
   - What's unclear: Best approach for creating test PhotoAssets without real PHAssets
   - Recommendation: Create a protocol `PhotoAssetProtocol` and use dependency injection, or create a test-specific initializer that doesn't require PHAsset

2. **Test Data for Embeddings**
   - What we know: Need 512-dimensional vectors for realistic tests
   - What's unclear: Whether to use random vectors, calculated vectors, or cached real embeddings
   - Recommendation: Use simple mathematical vectors (unit vectors, orthogonal pairs) for algorithm verification; don't need realistic 512-dim data

3. **groupSimilarPhotos Return Type Issue**
   - What we know: Current implementation returns `DuplicateGroup(photos: [], ...)` - empty photos array
   - What's unclear: Whether this is intentional placeholder or bug
   - Recommendation: Review and fix in implementation phase; test should verify photos are actually in groups

## Sources

### Primary (HIGH confidence)
- Apple XCTest Documentation (via training knowledge verified with patterns)
- [SwiftLee: Unit testing async/await](https://www.avanderlee.com/concurrency/unit-testing-async-await/) - Async testing patterns
- [SwiftLee: ContentUnavailableView](https://www.avanderlee.com/swiftui/contentunavailableview-handling-empty-states/) - Empty state patterns
- [SwiftLee: #expect macro](https://www.avanderlee.com/swift-testing/expect-macro/) - Swift Testing comparison

### Secondary (MEDIUM confidence)
- [Swift Senpai: Photo Library Permission](https://swiftsenpai.com/development/photo-library-permission/) - Permission handling patterns
- [Unit Testing Best Practices on iOS](https://www.vadimbulavin.com/unit-testing-best-practices-on-ios-with-swift/) - Float accuracy, test organization
- [Hacking with Swift: ContentUnavailableView](https://www.hackingwithswift.com/books/ios-swiftui/showing-empty-states-with-contentunavailableview) - Empty state examples

### Tertiary (LOW confidence)
- Community patterns for connected components testing - general graph algorithm testing strategies

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - XCTest is well-documented, ContentUnavailableView is standard iOS 17+
- Architecture: HIGH - Async actor testing patterns are well-established
- Pitfalls: HIGH - Float comparison and actor isolation issues are well-documented
- Code examples: MEDIUM - Based on documented patterns but untested in this specific codebase

**Research date:** 2026-01-27
**Valid until:** 60 days (stable technologies, no rapid changes expected)
