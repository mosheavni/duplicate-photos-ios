# Roadmap: Duplicate Photos iOS

**Created:** 2026-01-27
**Goal:** Get scan working reliably to detect duplicate photos
**Milestone:** v1.0 MVP

---

## Phase 70: Fix Embedding Dimension Mismatch

**Goal:** Scan correctly identifies duplicate photos in the simulator

**Why first:** Research identified the root cause - model outputs 768 dimensions but code expects 512. Nothing else matters until this works.

**Plans:** 1 plan

Plans:
- [x] 70-01-PLAN.md — Fix dimension mismatch, cache versioning, threshold update

### Requirements Addressed
- SCAN-01: Scan detects actual duplicate photos in the library
- SCAN-03: Scan completes without errors or crashes

### Success Criteria
- [x] Scan with 2+ duplicate photos returns at least 1 group
- [x] Self-similarity test (same image) scores = 1.0
- [x] Embedding dimension matches model output (768)

### Approach
1. Add diagnostic logging to EmbeddingService
2. Either update `embeddingDimension = 768` OR reconvert model to output 512
3. Handle MLMultiArray batch dimension if present
4. Clear cache and re-test with known duplicates

---

## Phase 71: Settings Screen

**Goal:** Users can adjust similarity threshold from the UI

**Why second:** Once scan works, threshold adjustment lets users fine-tune detection sensitivity.

**Plans:** 1 plan

Plans:
- [x] 71-01-PLAN.md — SettingsView with threshold slider, cache management, about section

### Requirements Addressed
- UI-01: Settings screen with adjustable similarity threshold

### Success Criteria
- [x] Settings view accessible from main screen
- [x] Slider to adjust threshold (0.85 - 0.98, default 0.92)
- [x] Threshold persists between app launches
- [x] Scan uses user-selected threshold

### Approach
1. Create SettingsView with SwiftUI slider
2. Store threshold in UserDefaults
3. Update ScanSettings to read from UserDefaults
4. Add navigation to Settings from ContentView

---

## Phase 72: Batch Operations

**Goal:** Users can delete multiple duplicates with one action

**Why third:** This is the primary user action after viewing results. High value, low complexity.

### Requirements Addressed
- (implied) Efficient duplicate management

### Success Criteria
- [ ] "Delete all but first" button in group detail view
- [ ] Confirmation dialog before batch delete
- [ ] Photos moved to Recently Deleted (iOS handles recovery)
- [ ] UI updates after deletion

### Approach
1. Add batch delete action to GroupDetailView
2. Use PHPhotoLibrary.shared().performChanges for atomic deletion
3. Update duplicateGroups state after deletion

---

## Phase 73: Polish and Testing

**Goal:** App is ready for personal use testing

### Requirements Addressed
- SCAN-02: Progress bar shows meaningful progress during scan
- TEST-01: Core services have unit test coverage

### Success Criteria
- [ ] Unit tests for SimilarityService (cosine similarity)
- [ ] Unit tests for connected components grouping
- [ ] Empty state UI when no duplicates found
- [ ] Error handling for permission denied

### Approach
1. Add XCTest cases for core algorithms
2. Improve empty state messaging
3. Handle authorization edge cases

---

## Phase Dependencies

```
Phase 70 (Fix Embeddings) [COMPLETE]
    |
Phase 71 (Settings) [COMPLETE] <--+
    |                  |
Phase 72 (Batch Ops)   | Can start after 70
    |                  |
Phase 73 (Polish) -----+
```

---

## Out of Scope (This Milestone)

- Video duplicate detection
- Smart "best to keep" selection
- Screenshot filtering
- Burst detection
- App Store submission

These are deferred to v1.1+ after core functionality is validated.

---

## Tracking

| Phase | Status | Started | Completed |
|-------|--------|---------|-----------|
| 70 | complete | 2026-01-27 | 2026-01-27 |
| 71 | complete | 2026-01-27 | 2026-01-27 |
| 72 | pending | - | - |
| 73 | pending | - | - |

---

*Roadmap created from research synthesis. Ready for phase planning.*
