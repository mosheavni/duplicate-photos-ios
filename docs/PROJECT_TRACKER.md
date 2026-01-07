# Duplicate Photos iOS - Project Tracker

## Project Overview
Native iOS app for detecting and managing duplicate photos using on-device CoreML processing.

**Tech Stack**: Swift, SwiftUI, CoreML, PHPhotoLibrary
**Timeline**: 8 weeks to MVP
**Repository**: https://github.com/[your-username]/duplicate-photos-ios

---

## Development Phases

### Phase 1: Foundation (Week 1-2)
**Goal**: Set up project and build core ML capabilities

- [ ] Epic 1: Project Setup & Environment
- [ ] Epic 2: CoreML Model Preparation
- [ ] Task 3.1: Photos Library Service
- [ ] Task 3.2: Similarity Search Service

**Deliverable**: Can scan photos and compute similarity

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

| Epic | Status | Tasks Complete | Notes |
|------|--------|----------------|-------|
| [Epic 1: Project Setup](epics/epic-1-project-setup.md) | 🔄 In Progress | 0/3 | Installing dependencies |
| [Epic 2: CoreML Model](epics/epic-2-coreml-model.md) | ⏳ Pending | 0/2 | Blocked by Xcode install |
| [Epic 3: Core Services](epics/epic-3-core-services.md) | ⏳ Pending | 0/4 | - |
| [Epic 4: User Interface](epics/epic-4-user-interface.md) | ⏳ Pending | 0/5 | - |
| [Epic 5: Architecture](epics/epic-5-architecture.md) | ⏳ Pending | 0/2 | - |
| [Epic 6: Testing & Polish](epics/epic-6-testing-polish.md) | ⏳ Pending | 0/4 | - |
| [Epic 7: Deployment](epics/epic-7-deployment.md) | ⏳ Pending | 0/2 | - |

**Legend**:
- ✅ Complete
- 🔄 In Progress
- ⏳ Pending
- ⚠️ Blocked

---

## Current Sprint

**Sprint Goal**: Complete Phase 1 (Foundation)

**Active Tasks**:
- [ ] Install Xcode 15+
- [ ] Install coremltools
- [ ] Install Git LFS
- [ ] Create Xcode project
- [ ] Set up .gitignore

---

## Blockers

1. **Xcode Installation Required** - Need to download from Mac App Store (~15GB)
2. **Apple Developer Account** - Need to configure (free tier is fine)

---

## Reference

- **Plan Document**: `~/.claude/plans/quirky-puzzling-island.md`
- **Python Reference**: Will be added as submodule to `Reference/duplicate-images/`
