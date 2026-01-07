# Epic 5: Data Layer & Architecture 🏛️

**Status**: ⏳ Pending
**Phase**: 3 - User Interface
**Duration**: 2-3 days

---

## Overview

Implement MVVM architecture to separate business logic from UI, creating ViewModels and data models.

---

## Tasks

### Task 5.1: MVVM Architecture Setup

**Files**:

- `DuplicatePhotos/ViewModels/ScanViewModel.swift`
- `DuplicatePhotos/ViewModels/DuplicateGroupViewModel.swift`
- `DuplicatePhotos/ViewModels/SettingsViewModel.swift`

#### Subtasks

- [ ] Create ScanViewModel.swift
  - @Published properties for scan state
  - Async scan methods
  - Progress handling
  - Error handling
- [ ] Create DuplicateGroupViewModel.swift
  - Handle group interactions
  - Selection state
  - Delete/merge actions
- [ ] Create SettingsViewModel.swift
  - Manage settings state
  - Persist to UserDefaults
  - Cache management
- [ ] Use @MainActor for UI updates
- [ ] Add error handling with Result types

---

### Task 5.2: Models

**Files**:

- `DuplicatePhotos/Models/PhotoAsset.swift`
- `DuplicatePhotos/Models/DuplicateGroup.swift`
- `DuplicatePhotos/Models/ScanSettings.swift`

#### Subtasks

- [ ] Create PhotoAsset.swift

  ```swift
  struct PhotoAsset: Identifiable {
      let id: String  // PHAsset.localIdentifier
      let asset: PHAsset
      let thumbnail: UIImage?
      var embedding: [Float]?
  }
  ```

- [ ] Create DuplicateGroup.swift

  ```swift
  struct DuplicateGroup: Identifiable {
      let id: UUID
      let photos: [PhotoAsset]
      let similarities: [Float]
  }
  ```

- [ ] Create ScanSettings.swift (Codable)

  ```swift
  struct ScanSettings: Codable {
      var threshold: Float = 0.90
      var batchSize: Int = 32
      var useCache: Bool = true
  }
  ```

- [ ] Add Codable conformance where needed
- [ ] Add Equatable/Hashable where needed
- [ ] Write unit tests

---

## Definition of Done

- [ ] MVVM architecture implemented
- [ ] ViewModels created for all screens
- [ ] Data models created
- [ ] UI properly separated from business logic
- [ ] Unit tests for ViewModels
- [ ] Unit tests for Models

---

## Dependencies

**Blocked By**:

- Epic 3 (Core Services) - ViewModels depend on services

**Blocks**:

- Epic 4 (User Interface) - Views depend on ViewModels
