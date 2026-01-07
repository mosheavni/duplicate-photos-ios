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
- [ ] Epic 2: CoreML Model Preparation (Ready to run)
- [x] Task 3.1: Photos Library Service ✅
- [x] Task 3.2: Similarity Search Service ✅

**Deliverable**: Can scan photos and compute similarity
**Status**: 90% Complete - Ready for model conversion

---

### Phase 2: Core Functionality (Week 3-4)

**Goal**: Build complete detection pipeline

- [ ] Task 3.3: Caching Service
- [ ] Task 3.4: Duplicate Detection Orchestrator
- [ ] Task 4.1: App Structure & Navigation
- [ ] Task 4.2: Scan Screen

**Deliverable**: Working scan with results

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

| Epic                                                       | Status     | Tasks Complete | Notes                          |
| ---------------------------------------------------------- | ---------- | -------------- | ------------------------------ |
| [Epic 1: Project Setup](epics/epic-1-project-setup.md)     | ✅ Complete | 3/3            | Xcode project created          |
| [Epic 2: CoreML Model](epics/epic-2-coreml-model.md)       | 🔄 Ready   | 0/2            | Conversion script ready        |
| [Epic 3: Core Services](epics/epic-3-core-services.md)     | ✅ Complete | 4/4            | All services implemented       |
| [Epic 4: User Interface](epics/epic-4-user-interface.md)   | 🔄 Started | 1/5            | Basic UI structure in place    |
| [Epic 5: Architecture](epics/epic-5-architecture.md)       | ✅ Complete | 2/2            | MVVM structure implemented     |
| [Epic 6: Testing & Polish](epics/epic-6-testing-polish.md) | ⏳ Pending  | 0/4            | -                              |
| [Epic 7: Deployment](epics/epic-7-deployment.md)           | ⏳ Pending  | 0/2            | -                              |

**Legend**:

- ✅ Complete
- 🔄 In Progress
- ⏳ Pending
- ⚠️ Blocked

---

## Current Sprint

**Sprint Goal**: Complete Phase 1 (Foundation)

**Active Tasks**:

- [x] Install Xcode 15+ ✅ Xcode 26.2
- [x] Install coremltools ✅ Version 9.0
- [x] Install Git LFS ✅ Version 3.7.1
- [x] Create Xcode project ✅ DuplicatePhotos.xcodeproj
- [x] Set up .gitignore ✅ Complete

**Next Steps**:

- [ ] Run CLIP model conversion: `python3 scripts/convert_clip_to_coreml.py`
- [ ] Open project in Xcode and test build
- [ ] Configure Apple Developer Account in Xcode

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
