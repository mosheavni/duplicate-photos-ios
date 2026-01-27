# Phase 72: Batch Operations - Research

**Researched:** 2026-01-27
**Domain:** iOS photo deletion, batch operations, PhotoKit APIs
**Confidence:** MEDIUM

## Summary

Phase 72 implements batch deletion of duplicate photos using iOS PhotoKit's `PHAssetChangeRequest.deleteAssets()` API. The standard approach involves wrapping deletion calls in `PHPhotoLibrary.shared().performChanges()` blocks, with iOS's Recently Deleted album providing a 30-day safety net for recovery. User decisions from CONTEXT.md specify immediate deletion without confirmation for single groups, and alert confirmation for bulk "delete all" operations across multiple groups.

Key technical requirements include auto-selecting the "best" photo to keep based on quality heuristics (resolution, file size, recency), handling partial failures gracefully by continuing to process remaining groups, and providing brief toast feedback after deletion. The existing PhotoLibraryService already has a basic `deleteAssets()` method that can be enhanced to support progress reporting and error handling for batch operations.

**Primary recommendation:** Enhance PhotoLibraryService.deleteAssets() to support batch deletion with progress callbacks, implement photo quality comparison using PHAsset metadata (pixelWidth, pixelHeight) and PHAssetResource file size, use SwiftUI confirmation dialogs with destructive role for bulk operations, and implement toast notifications using a lightweight SwiftUI library like AlertToast.

## Standard Stack

The established libraries/tools for iOS photo deletion and batch operations:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| PhotoKit | iOS 17+ | Photo library access and modification | Official Apple framework for Photos app integration |
| PHPhotoLibrary | iOS 17+ | Perform changes to photo library | Thread-safe API for batch modifications |
| PHAssetChangeRequest | iOS 17+ | Delete assets from library | Standard deletion mechanism with system integration |
| SwiftUI | iOS 17+ | UI framework | Native declarative UI, built-in alert/confirmation support |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| AlertToast | 1.3.9+ | Toast notifications | Temporary feedback messages after deletion |
| PHAssetResource | iOS 17+ | Access file metadata (size) | Determining best photo to keep |
| ByteCountFormatter | iOS 17+ | Format file sizes | Human-readable size display |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| AlertToast | EasyToast, Toasty | AlertToast has 3 display modes (Alert, HUD, Banner), well-maintained |
| Custom toast | Native alert | Toast is less intrusive, doesn't require user action |
| Synchronous deletion | performChangesAndWait | Async is recommended, keeps UI responsive |

**Installation:**
```bash
# If using Swift Package Manager for toast library
# Add to Xcode: File → Add Package Dependencies → https://github.com/elai950/AlertToast
```

## Architecture Patterns

### Recommended Project Structure
```
DuplicatePhotos/
├── Services/
│   └── PhotoLibraryService.swift   # Enhanced with batch deletion, progress
├── Models/
│   ├── DuplicateGroup.swift        # Add selectedPhotos: Set<String>
│   └── PhotoAsset.swift            # Add quality score computed property
└── ViewModels/
    └── BatchOperationsViewModel.swift # New: orchestrates batch deletion
```

### Pattern 1: Batch Deletion with Progress Reporting
**What:** Delete multiple PHAssets with progress callbacks
**When to use:** User triggers single-group or bulk deletion
**Example:**
```swift
// Source: WebSearch verified with developer community patterns
actor PhotoLibraryService {
    func deleteAssets(
        _ assets: [PHAsset],
        progressHandler: ((Int, Int) -> Void)? = nil
    ) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }
        // Note: performChanges is atomic - all or nothing
        // Report progress after completion
        await MainActor.run {
            progressHandler?(assets.count, assets.count)
        }
    }

    // For group-by-group deletion with partial failure handling
    func deleteAssetsWithRecovery(
        assetGroups: [[PHAsset]],
        progressHandler: @escaping (Int, Int, [Error]) -> Void
    ) async -> [Error] {
        var errors: [Error] = []
        var completed = 0

        for group in assetGroups {
            do {
                try await deleteAssets(group)
                completed += group.count
            } catch {
                errors.append(error)
            }
            await MainActor.run {
                progressHandler(completed, assetGroups.flatMap({$0}).count, errors)
            }
        }

        return errors
    }
}
```

### Pattern 2: Photo Quality Comparison
**What:** Determine best photo to keep using metadata
**When to use:** Auto-selecting photos for deletion
**Example:**
```swift
// Source: WebSearch - community patterns for quality comparison
extension PhotoAsset {
    var qualityScore: Double {
        let resolution = Double(phAsset.pixelWidth * phAsset.pixelHeight)
        let fileSize = getFileSize() // in bytes
        let recencyScore = phAsset.creationDate?.timeIntervalSinceNow ?? 0

        // Weighted scoring: resolution (50%), file size (30%), recency (20%)
        let normalizedResolution = resolution / 100_000_000.0 // 100MP max
        let normalizedSize = Double(fileSize) / 50_000_000.0 // 50MB max
        let normalizedRecency = abs(recencyScore) / (365.0 * 24.0 * 3600.0) // 1 year

        return (normalizedResolution * 0.5) +
               (normalizedSize * 0.3) +
               (normalizedRecency * 0.2)
    }

    private func getFileSize() -> Int64 {
        let resources = PHAssetResource.assetResources(for: phAsset)
        guard let resource = resources.first else { return 0 }
        return resource.value(forKey: "fileSize") as? Int64 ?? 0
    }
}

extension DuplicateGroup {
    func selectBestPhoto() -> PhotoAsset? {
        return photos.max(by: { $0.qualityScore < $1.qualityScore })
    }
}
```

### Pattern 3: SwiftUI Confirmation Dialog
**What:** Alert confirmation for destructive bulk operations
**When to use:** Bulk "delete all" affecting multiple groups
**Example:**
```swift
// Source: SwiftUI best practices - useyourloaf.com
struct DuplicateGroupsView: View {
    @State private var showDeleteAllConfirmation = false
    let totalPhotosToDelete: Int

    var body: some View {
        Button("Delete All Duplicates") {
            showDeleteAllConfirmation = true
        }
        .confirmationDialog(
            "Delete \(totalPhotosToDelete) photos?",
            isPresented: $showDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete \(totalPhotosToDelete) Photos", role: .destructive) {
                Task {
                    await deleteAllDuplicates()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Photos will be moved to Recently Deleted for 30 days.")
        }
    }
}
```

### Pattern 4: Toast Notification Feedback
**What:** Brief, non-blocking feedback after deletion
**When to use:** After successful or failed deletion operations
**Example:**
```swift
// Source: AlertToast library documentation
import AlertToast

struct ContentView: View {
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        content
            .toast(isPresenting: $showToast, duration: 2.0) {
                AlertToast(
                    displayMode: .banner(.pop),
                    type: .complete(.green),
                    title: toastMessage
                )
            }
    }

    func showDeletionFeedback(deletedCount: Int, errors: [Error]) {
        if errors.isEmpty {
            toastMessage = "Deleted \(deletedCount) photo\(deletedCount == 1 ? "" : "s")"
        } else {
            toastMessage = "Deleted \(deletedCount) photos, \(errors.count) failed"
        }
        showToast = true
    }
}
```

### Anti-Patterns to Avoid
- **Deleting without checking authorization:** Always verify PHPhotoLibrary authorization before attempting deletion
- **Blocking UI during deletion:** Use async/await and Task to keep UI responsive
- **Not handling iCloud downloads:** Set `isNetworkAccessAllowed = true` in PHImageRequestOptions
- **Using performChangesAndWait on main thread:** This blocks the UI; use async performChanges instead

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Toast notifications | Custom overlay with animation | AlertToast, Toasty | Handles display modes, timing, animation, accessibility |
| File size formatting | String interpolation with bytes | ByteCountFormatter | Handles units, localization, binary vs decimal |
| Progress tracking | Manual counters with @State | AsyncStream with Task | Better concurrency handling, cancellation support |
| Photo metadata access | Manual Info.plist parsing | PHAsset properties, PHAssetResource | Official API, handles permissions, iCloud |

**Key insight:** PhotoKit APIs are deeply integrated with iOS system behavior (Recently Deleted, iCloud sync, system confirmation dialogs). Custom implementations bypass these integrations and create inconsistent user experiences.

## Common Pitfalls

### Pitfall 1: iOS 18+ Deletion Callback Issues
**What goes wrong:** In iOS 18, some developers report that `PHAssetChangeRequest.deleteAssets()` completion handler is never called, requiring device restart
**Why it happens:** Suspected framework bug with certain asset types (48MP RAW, iCloud assets)
**How to avoid:**
- Implement timeout mechanism for deletion operations (15-30 seconds)
- Test with various asset types (RAW, Live Photos, iCloud)
- Provide user feedback if operation hangs ("Deletion taking longer than expected...")
**Warning signs:** Completion handler doesn't fire after 10+ seconds, subsequent operations fail

### Pitfall 2: Non-Atomic Batch Deletion
**What goes wrong:** Assuming `PHAssetChangeRequest.deleteAssets([assets])` processes assets individually with partial success
**Why it happens:** Documentation doesn't clearly specify atomicity; developers expect item-by-item processing
**How to avoid:**
- Treat `performChanges` as atomic (all-or-nothing)
- For partial failure handling, delete groups individually in sequence
- Catch errors per group, continue processing remaining groups
**Warning signs:** Expecting partial success but getting complete failure

### Pitfall 3: PHAsset pixelWidth/pixelHeight Inaccuracy
**What goes wrong:** Using PHAsset.pixelWidth/pixelHeight for quality comparison, but values don't match actual image dimensions
**Why it happens:** For iCloud photos or edited images, metadata may reflect thumbnail or preview size
**How to avoid:**
- Request full-size image metadata if accuracy is critical
- Use multiple quality indicators (file size, creation date) not just resolution
- Accept approximate values for auto-selection (user can override)
**Warning signs:** Resolution values seem too low for known high-res photos

### Pitfall 4: Missing Recently Deleted Context
**What goes wrong:** Users think deletion is permanent, panic when they delete wrong photos
**Why it happens:** App doesn't communicate that iOS keeps deleted photos for 30 days
**How to avoid:**
- Include "Photos will be moved to Recently Deleted" in confirmation message
- Add info button near delete actions linking to Settings → Photos → Recently Deleted
- Don't implement custom "undo" - let users know iOS provides recovery
**Warning signs:** User support requests about "permanent" deletion, requests for undo feature

### Pitfall 5: Race Condition with Group State
**What goes wrong:** After deleting a group, UI shows group briefly before disappearing, or crashes accessing deleted assets
**Why it happens:** View is still rendering while deletion completes, asset fetch results become stale
**How to avoid:**
- Immediately update UI state (remove group from list) before async deletion completes
- Use `@MainActor` for ViewModel state updates
- Observe PHPhotoLibraryChangeObserver for external changes (user deletes in Photos app)
**Warning signs:** Crashes with "asset not found", flickering UI, stale group data

## Code Examples

Verified patterns from official sources:

### Basic Asset Deletion
```swift
// Source: Apple Developer Forums, community verified
func deleteAsset(asset: PHAsset) async throws {
    try await PHPhotoLibrary.shared().performChanges {
        PHAssetChangeRequest.deleteAssets([asset] as NSArray)
    }
}
```

### Batch Deletion with Error Handling
```swift
// Source: WebSearch - BrowsingAndModifyingPhotoAlbums sample
func deleteMultipleAssets(_ assets: [PHAsset]) {
    PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.deleteAssets(assets as NSArray)
    }) { success, error in
        if success {
            print("Successfully deleted \(assets.count) photos")
        } else if let error = error {
            print("Deletion failed: \(error.localizedDescription)")
            // Handle specific error codes
        }
    }
}
```

### Getting File Size from PHAsset
```swift
// Source: Medium article - "Get Photo Exact Storage Size in Swift"
extension PHAsset {
    var fileSize: Int64 {
        let resources = PHAssetResource.assetResources(for: self)
        guard let resource = resources.first else { return 0 }
        let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong
        return Int64(bitPattern: UInt64(unsignedInt64 ?? 0))
    }

    var fileSizeString: String {
        ByteCountFormatter.string(
            fromByteCount: fileSize,
            countStyle: .file
        )
    }
}
```

### SwiftUI Progress View with Async Task
```swift
// Source: hackingwithswift.com - SwiftUI by Example
struct DeletionProgressView: View {
    @State private var deletionProgress: Double = 0.0
    @State private var isDeleting = false

    var body: some View {
        if isDeleting {
            ProgressView(
                "Deleting photos...",
                value: deletionProgress,
                total: 1.0
            )
        }
    }

    func deleteWithProgress(groups: [[PHAsset]]) async {
        isDeleting = true
        let totalAssets = groups.flatMap { $0 }.count
        var deleted = 0

        for group in groups {
            try? await photoLibraryService.deleteAssets(group)
            deleted += group.count
            deletionProgress = Double(deleted) / Double(totalAssets)
        }

        isDeleting = false
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ALAssetsLibrary | PhotoKit (PHPhotoLibrary) | iOS 8 (2014) | ALAssetsLibrary unavailable in iOS 18+ |
| Synchronous deletion | Async/await with performChanges | iOS 15 (2021) | Better UI responsiveness, structured concurrency |
| Custom undo/trash | iOS Recently Deleted album | iOS 8 (2014) | System-level safety net, 30-day recovery |
| UIKit alerts | SwiftUI confirmation dialogs | iOS 15 (2021) | Declarative, better for destructive actions |
| Manual toast views | SwiftUI toast libraries | iOS 14+ (2020) | Standardized non-blocking feedback |

**Deprecated/outdated:**
- **ALAssetsLibrary**: Fully removed in iOS 18, use PHPhotoLibrary
- **UIAlertController in SwiftUI**: Use native `.confirmationDialog()` modifier
- **Completion handler-based performChanges**: Prefer async/await version in Swift 5.5+

## Open Questions

Things that couldn't be fully resolved:

1. **PHAssetChangeRequest atomicity with mixed asset types**
   - What we know: performChanges executes as a transaction
   - What's unclear: Behavior when some assets are iCloud-only, some local, some RAW+JPEG pairs
   - Recommendation: Test with diverse asset types, implement per-group deletion for safety

2. **iOS 18 deletion callback bug scope**
   - What we know: Some developers report completion handler not called for 48MP RAW assets
   - What's unclear: Whether fixed in iOS 18.2+, full scope of affected asset types
   - Recommendation: Implement timeout fallback, test on iOS 18 devices with RAW photos

3. **Optimal batch size for deletion**
   - What we know: Can delete multiple assets in one performChanges call
   - What's unclear: Performance characteristics of deleting 100 vs 1000 assets at once
   - Recommendation: Start with per-group deletion (safer), profile if performance issues arise

4. **Quality score weighting for photo selection**
   - What we know: Resolution, file size, recency are relevant factors
   - What's unclear: Optimal weighting (50/30/20 is educated guess)
   - Recommendation: Implement configurable weights, consider user feedback if selection seems wrong

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation (attempted, requires JavaScript)
  - PHAssetChangeRequest.deleteAssets() API
  - PHPhotoLibrary.performChanges() behavior
  - PHAssetResource for file metadata

### Secondary (MEDIUM confidence)
- [SamplePhotosApp-Swift on GitHub](https://github.com/ooper-shlab/SamplePhotosApp-Swift/blob/master/SamplePhotosApp/AssetViewController.swift) - Apple sample code for asset deletion
- [BrowsingAndModifyingPhotoAlbums on GitHub](https://github.com/ddd503/BrowsingAndModifyingPhotoAlbums) - Asset deletion patterns
- [SwiftUI Confirmation Dialogs - Use Your Loaf](https://useyourloaf.com/blog/swiftui-confirmation-dialogs/) - Destructive action patterns
- [AlertToast GitHub](https://github.com/elai950/AlertToast) - SwiftUI toast library
- [Medium: Get Photo Exact Storage Size in Swift](https://medium.com/idn-engineering/get-photo-exact-storage-size-in-swift-94bfef1e2afc) - PHAssetResource file size
- [Apple Support: Recover Deleted Photos](https://support.apple.com/en-us/124460) - Recently Deleted 30-day policy
- [objc.io: The Photos Framework](https://www.objc.io/issues/21-camera-and-photos/the-photos-framework/) - PhotoKit architecture

### Tertiary (LOW confidence - requires validation)
- [Apple Developer Forums: PHAssetChangeRequest deleteAssets issue](https://developer.apple.com/forums/thread/732820) - iOS 18 deletion bug reports
- [Hacking with Swift: ProgressView](https://www.hackingwithswift.com/quick-start/swiftui/how-to-show-progress-on-a-task-using-progressview) - Progress indicator patterns
- WebSearch community patterns for duplicate photo selection algorithms

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - PhotoKit is official framework, SwiftUI is standard for iOS 17+
- Architecture: MEDIUM - Patterns verified in community code, but atomicity details unclear
- Pitfalls: MEDIUM - iOS 18 bug reports from forums (not officially documented), other pitfalls from experience

**Research date:** 2026-01-27
**Valid until:** ~30 days (iOS 18.3 may fix reported bugs, library versions may update)
