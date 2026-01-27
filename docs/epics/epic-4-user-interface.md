# Epic 4: User Interface 📱

**Status**: 🔄 In Progress (3/5 tasks complete)
**Phase**: 2-3 - Core Functionality & User Interface
**Duration**: 2 weeks

---

## Overview

Build beautiful, intuitive SwiftUI interfaces for scanning, viewing, and managing duplicate photos.

---

## Tasks

### Task 4.1: App Structure & Navigation

**Files**:

- `DuplicatePhotos/App/DuplicatePhotosApp.swift`
- `DuplicatePhotos/Views/ContentView.swift`

- [ ] Create app entry point
- [ ] Set up NavigationStack
- [ ] Add tab bar (optional)
- [ ] Configure app icon and display name
- [ ] Add Info.plist keys:
  - `NSPhotoLibraryUsageDescription`
  - `NSPhotoLibraryAddUsageDescription`

---

### Task 4.2: Scan Screen

**File**: `DuplicatePhotos/Views/ScanView.swift`
**Status**: ✅ Complete

- [x] Create ScanView.swift ✅
- [x] Design beautiful scan button ✅
- [x] Add progress indicator (linear with animation) ✅
- [x] Show photo count while scanning ✅
- [x] Display results summary ✅
- [x] Handle permissions request UI ✅
- [ ] Add pull-to-refresh (Future enhancement)
- [x] Empty state (no duplicates found) ✅

---

### Task 4.3: Duplicate Groups List

**File**: `DuplicatePhotos/Views/DuplicateGroupsListView.swift`
**Status**: ✅ Complete

- [x] Create DuplicateGroupsListView.swift ✅
- [x] Design group card component ✅
- [x] Implement LazyVStack layout ✅
- [x] Add thumbnail loading (async) ✅
- [x] Show similarity badge ✅
- [x] Add tap gesture to navigate to detail ✅
- [x] Show group count ("3 duplicates") ✅

**Design Inspiration**: iOS Photos app duplicate detection

---

### Task 4.4: Duplicate Group Detail View

**File**: `DuplicatePhotos/Views/GroupDetailView.swift`
**Status**: ✅ Complete

- [x] Create GroupDetailView.swift ✅
- [x] Add photo grid (2-column LazyVGrid) ✅
- [x] Implement selection UI (checkmarks) ✅
- [x] Add "Keep Best, Delete Others" action ✅
- [x] Add "Keep All" action ✅
- [x] Add "Delete Selected" action ✅
- [x] Show metadata (file size, dimensions) ✅
- [ ] Add undo support (iOS 16+ UndoManager) (Future enhancement)
- [x] Implement smooth animations ✅

---

### Task 4.5: Settings Screen

**File**: `DuplicatePhotos/Views/SettingsView.swift`

- [ ] Create SettingsView.swift
- [ ] Add threshold slider (0.80 - 0.95)
  - Labels: "More duplicates" ↔ "Fewer duplicates"
  - Default: 0.90
- [ ] Add batch size stepper (16/32/64)
- [ ] Add cache toggle
- [ ] Add "Clear Cache" button with confirmation
- [ ] Show cache statistics (size, count)
- [ ] Persist settings with UserDefaults
- [ ] Add info tooltips (help icons)

**Python Reference**: `src/duplicate_images/config/defaults.py`

---

## Definition of Done

- [ ] All 5 screens created and functional
- [ ] Navigation flows correctly
- [ ] UI matches iOS design guidelines
- [ ] Animations are smooth (60fps)
- [ ] Dark mode supported
- [ ] Works on iPhone and iPad
- [ ] Accessible (VoiceOver labels)

---

## Dependencies

**Blocked By**:

- Epic 3 (Core Services) - needs DuplicateDetector
- Epic 5 (Architecture) - needs ViewModels

---

## Design Guidelines

- Use iOS native components (SF Symbols, standard controls)
- Follow Human Interface Guidelines
- Support both light and dark mode
- Maintain 60fps scrolling performance
- Use spring animations for smooth feel
