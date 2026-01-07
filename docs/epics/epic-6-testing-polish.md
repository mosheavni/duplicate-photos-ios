# Epic 6: Testing & Polish ✨

**Status**: ⏳ Pending
**Phase**: 4 - Testing & Release
**Duration**: 1 week

---

## Overview
Comprehensive testing, performance optimization, and UI/UX polish before beta release.

---

## Tasks

### Task 6.1: Unit Tests

**Coverage Targets**: >70% code coverage

- [ ] Write tests for EmbeddingService
  - Model loading
  - Image preprocessing
  - Embedding extraction
  - Batch processing
- [ ] Write tests for SimilarityService
  - Cosine similarity accuracy
  - Grouping algorithm (DFS)
  - Edge cases (empty, single item)
- [ ] Write tests for CacheService
  - CRUD operations
  - Cache invalidation
  - Size limits
- [ ] Write tests for DuplicateDetector
  - Full pipeline
  - Progress tracking
  - Cancellation
- [ ] Create mock data for testing
  - Sample images
  - Known duplicate sets
- [ ] Aim for >70% code coverage

---

### Task 6.2: UI Testing

**Test Scenarios**:
- [ ] Scan flow (happy path)
- [ ] Handle no duplicates found
- [ ] Handle photo library permission denied
- [ ] Merge duplicates action
- [ ] Delete photos action
- [ ] Change settings
- [ ] Test on different device sizes:
  - iPhone SE (small screen)
  - iPhone 15 Pro (standard)
  - iPhone 15 Pro Max (large)
  - iPad (tablet layout)

---

### Task 6.3: Performance Optimization

**Performance Targets**:
- Scan 1000 photos in <30 seconds
- Smooth 60fps scrolling
- Memory usage <500MB for 10k photos

#### Subtasks:
- [ ] Profile with Instruments
  - Time Profiler (CPU usage)
  - Allocations (memory usage)
  - Leaks (memory leaks)
- [ ] Optimize image loading
  - Thumbnail caching
  - Lazy loading
  - Image decoding off main thread
- [ ] Optimize similarity search
  - Use Accelerate framework (vDSP)
  - Batch operations where possible
- [ ] Test on older devices
  - iPhone 12 (A14 chip)
  - iPhone 13 (A15 chip)
- [ ] Handle memory warnings
  - Clear caches
  - Release unused resources

---

### Task 6.4: Polish & UX

**Nice-to-haves**:
- [ ] Add haptic feedback
  - On button taps
  - On delete/merge actions
- [ ] Polish animations
  - Use spring animations
  - Smooth transitions
  - Loading states
- [ ] Test dark mode appearance
  - Check colors work in both modes
  - Test with system toggle
- [ ] Add accessibility labels
  - VoiceOver support
  - Dynamic Type support
  - High Contrast support
- [ ] Design app icon
  - 1024x1024 required
  - Commission designer or create
- [ ] Create App Store screenshots
  - 6.5" (iPhone 15 Pro Max)
  - 5.5" (older devices)

---

## Definition of Done

- [ ] Unit test coverage >70%
- [ ] All UI tests passing
- [ ] Performance targets met
- [ ] No memory leaks detected
- [ ] Works on iPhone 12 and newer
- [ ] Fully accessible (VoiceOver works)
- [ ] Dark mode fully supported
- [ ] App icon designed and added

---

## Dependencies

**Blocked By**:
- All previous epics must be complete
