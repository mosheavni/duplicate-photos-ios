# Duplicate Photos iOS

## What This Is

A native iOS app for detecting and managing duplicate photos using on-device CoreML processing. Users scan their photo library, see grouped duplicates, and delete unwanted copies. All processing happens locally using CLIP embeddings for visual similarity.

## Core Value

**Scan works reliably**: Users tap "Start Scan", the app finds their duplicate photos, and they can delete the extras. If scanning doesn't find obvious duplicates, everything else is useless.

## Requirements

### Validated

<!-- Shipped and working based on existing code -->

- ✓ Photo library access with authorization handling — existing
- ✓ CoreML CLIP model integration for embeddings — existing
- ✓ UI skeleton (ContentView, ScanView, GroupsListView, GroupDetailView) — existing
- ✓ MVVM architecture with actor-based services — existing
- ✓ Photo deletion from library — existing

### Active

<!-- Current scope. Building toward these. -->

- [ ] **SCAN-01**: Scan detects actual duplicate photos in the library
- [ ] **SCAN-02**: Progress bar shows meaningful progress during scan
- [ ] **SCAN-03**: Scan completes without errors or crashes
- [ ] **UI-01**: Settings screen with adjustable similarity threshold
- [ ] **TEST-01**: Core services have unit test coverage

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Video duplicate detection — complexity, focus on photos first
- Cloud/iCloud comparison — on-device only for privacy and simplicity
- Merge duplicates — start with delete-only, simpler UX
- Real-time background scanning — battery/performance concerns

## Context

**Current State**: Scan runs but returns "No duplicates found" even with exact copy duplicates in the simulator. Comprehensive logging was added to diagnose the issue. The pipeline stages (fetch → embed → compare → group) need verification.

**Codebase**: ~13 Swift files, MVVM pattern, actor-based services for concurrency safety. CoreML CLIP model (~350MB) packaged in app bundle. No external dependencies.

**Testing Environment**: Xcode 26.2, iOS 17 simulator, test photos with exact duplicates added.

**Prior Issues Fixed**:
- Git LFS configured for large model file
- Xcode debug configuration updated
- Debugging logs added throughout pipeline

## Constraints

- **Platform**: iOS 17.0+ (Swift 6.0, SwiftUI only)
- **Device**: iPhone 12+ (A14 chip minimum for CoreML performance)
- **Performance**: Scan 1000 photos in <30 seconds
- **Privacy**: All processing on-device, no network calls
- **Model**: CLIP vision model (512-dim embeddings, ~350MB)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| CLIP for embeddings | Proven visual similarity, pre-trained, good accuracy | — Pending verification |
| Actor-based services | Thread safety for concurrent CoreML inference | ✓ Good |
| JSON file cache | Simple, no CoreData dependency | — Pending |
| Similarity threshold 0.80 | Lowered from 0.85 for testing | — Pending |

---
*Last updated: 2026-01-27 after initialization*
