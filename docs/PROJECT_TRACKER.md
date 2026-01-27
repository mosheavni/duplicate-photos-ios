# Duplicate Photos iOS - Project Tracker

## Project Overview

Native iOS app for detecting and managing duplicate photos using on-device CoreML processing.

**Tech Stack**: Swift, SwiftUI, CoreML, PHPhotoLibrary
**Timeline**: 8 weeks to MVP
**Repository**: <https://github.com/mosheavni/duplicate-photos-ios>

---

## Development Phases

### Phase 1: Foundation (Week 1-2)

**Goal**: Set up project and build core ML capabilities

- [x] Epic 1: Project Setup & Environment ✅
- [x] Epic 2: CoreML Model Preparation ✅
- [x] Task 3.1: Photos Library Service ✅
- [x] Task 3.2: Similarity Search Service ✅

**Deliverable**: Can scan photos and compute similarity
**Status**: ✅ 100% Complete - Real CLIP model integrated, ready for Phase 2

---

### Phase 2: Core Functionality (Week 3-4)

**Goal**: Build complete detection pipeline

- [x] Task 3.3: Caching Service ✅
- [x] Task 3.4: Duplicate Detection Orchestrator ✅
- [x] Task 4.1: App Structure & Navigation ✅
- [x] Task 4.2: Scan Screen ✅
- [x] Task 4.3: Duplicate Groups List ✅
- [x] Task 4.4: Group Detail View ✅

**Deliverable**: Working scan with results
**Status**: ✅ Complete - Full duplicate detection UI implemented

---

### Phase 3: User Interface (Week 5-6)

**Goal**: Build beautiful UI with merge/delete functionality

- [ ] Task 4.3: Duplicate Groups List
- [ ] Task 4.4: Group Detail View
- [ ] Task 4.5: Settings Screen
- [ ] Epic 5: MVVM Architecture

**Deliverable**: Full UI with merge/delete

---

### Phase 4: Testing & Release (Week 7-8)

**Goal**: Polish and release beta

- [ ] Epic 6: Testing & Polish
- [ ] Epic 7: TestFlight Beta

**Deliverable**: Beta-ready app

---

## Epic Status

| Epic                                                       | Status      | Tasks Complete | Notes                                      |
| ---------------------------------------------------------- | ----------- | -------------- | ------------------------------------------ |
| [Epic 1: Project Setup](epics/epic-1-project-setup.md)     | ✅ Complete | 3/3            | Xcode project created                      |
| [Epic 2: CoreML Model](epics/epic-2-coreml-model.md)       | ✅ Complete | 2/2            | Real CLIP model integrated                 |
| [Epic 3: Core Services](epics/epic-3-core-services.md)     | ✅ Complete | 4/4            | All services implemented                   |
| [Epic 4: User Interface](epics/epic-4-user-interface.md)   | 🔄 Started  | 3/5            | Scan, Groups List, Detail views complete  |
| [Epic 5: Architecture](epics/epic-5-architecture.md)       | ✅ Complete | 2/2            | MVVM structure implemented                 |
| [Epic 6: Testing & Polish](epics/epic-6-testing-polish.md) | ⏳ Pending   | 0/4            | -                                          |
| [Epic 7: Deployment](epics/epic-7-deployment.md)           | ⏳ Pending   | 0/2            | -                                          |

**Legend**:

- ✅ Complete
- 🔄 In Progress
- ⏳ Pending
- ⚠️ Blocked

---

## Current Sprint

**Sprint Goal**: Phase 2 Complete - Full Duplicate Detection UI

**Completed in Phase 2**:

- [x] Enhanced scan progress UI with animations ✅
- [x] Built duplicate groups list view ✅
- [x] Created group detail view with photo grid ✅
- [x] Implemented photo deletion functionality ✅
- [x] Added metadata display (file size, dimensions) ✅
- [x] Successful build on simulator ✅

**Next Steps (Phase 3)**:

- [ ] Add Settings screen (Task 4.5)
- [ ] Implement cache management UI
- [ ] Add app icon and launch screen
- [ ] Polish animations and transitions
- [ ] Begin testing phase

---

## Blockers

None - All prerequisites complete!

**Resolved**:

1. ~~Xcode Installation~~ ✅ Xcode 26.2 installed
2. **Apple Developer Account** - User needs to configure in Xcode (free tier is fine)

---

## Reference

- **Plan Document**: `~/.claude/plans/quirky-puzzling-island.md`
- **Python Reference**: Will be added as submodule to `Reference/duplicate-images/`
