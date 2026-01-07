# Epic 1: Project Setup & Environment 🏗️

**Status**: ✅ Complete
**Phase**: 1 - Foundation
**Duration**: 2-3 days
**Completed**: 2026-01-07

---

## Overview

Set up the development environment and create the iOS project structure with proper tooling and configuration.

---

## Tasks

### Task 1.1: Development Environment Setup

**Status**: ✅ Complete

#### Required Installations

- [x] **Xcode 15+** (from Mac App Store) ✅ Xcode 26.2 installed
  - ~15GB download
  - Includes Swift compiler, SwiftUI, iOS Simulator
- [x] **Apple Developer Account** (needs user configuration)
  - Sign in at developer.apple.com
  - Configure in Xcode preferences
- [x] **Command Line Tools**: ✅ Already installed
  - Swift 6.2.3 verified

#### Python Dependencies for Model Conversion

- [x] **coremltools**: ✅ Version 9.0 installed
  - Python: ✅ 3.14.0 (already installed)
  - PyTorch: ✅ 2.9.1 (already installed)
  - Transformers: ✅ 4.57.3 (already installed)
- [x] **Git LFS**: ✅ Version 3.7.1 installed
  - For managing large model files (~350MB)
  - Configured to track *.mlmodel and *.mlpackage files

#### Verification

```bash
# After installations, verify:
xcodebuild -version          # Should show Xcode 15+
swift --version              # Should show Swift 5.9+
pip3 list | grep coremltools # Should show version
git lfs version              # Should show installed
```

---

### Task 1.2: Create New iOS Project Repository

**Status**: ✅ Complete

#### Repository Structure

```
duplicate-photos-ios/
├── DuplicatePhotos/                    # Main app target
│   ├── App/                            # App entry point
│   ├── Models/                         # Data models & ML
│   ├── Views/                          # SwiftUI views
│   ├── ViewModels/                     # MVVM view models
│   ├── Services/                       # Core services
│   └── Resources/                      # Assets, CoreML models
├── DuplicatePhotosTests/               # Unit tests
├── DuplicatePhotosUITests/             # UI tests
├── Shared/                             # Shared utilities
├── scripts/                            # Build/conversion scripts
├── docs/                               # Documentation
│   ├── epics/                          # Epic tracking
│   └── PROJECT_TRACKER.md              # Main tracker
└── Reference/                          # Python repo (submodule)
```

#### Subtasks

- [x] Create new Xcode project ✅ Created using XcodeGen
  - Generated DuplicatePhotos.xcodeproj
  - iOS target with SwiftUI
  - Language: Swift 6.0
  - Deployment target: iOS 17.0
- [x] Initialize Git repository ✅ Already initialized
  - Repository active with commits
- [x] Set up .gitignore ✅ Already configured
  - Xcode template in place
  - Git LFS tracked files configured
- [x] Configure Git LFS for .mlmodel files ✅ Complete
  - Tracking *.mlmodel and *.mlpackage
  - .gitattributes committed
- [x] Create README.md ✅ Already exists
  - Project description
  - Setup instructions
  - Development status
- [x] Add LICENSE ✅ Already exists
  - MIT License

---

### Task 1.3: Add Python CLI as Git Submodule

**Status**: ✅ Complete

#### Purpose

Keep reference to original Python implementation for algorithm comparison and porting.

#### Subtasks

- [x] Add Python repo as submodule ✅ Complete

  ```bash
  Added: https://github.com/mosheavni/duplicated-images
  Location: Reference/duplicate-images
  ```

- [ ] Document Python → Swift mapping (Future enhancement)
  - Create `docs/PYTHON_TO_SWIFT.md`
  - Map each Python file to planned Swift file
  - Document algorithm translations
- [ ] Create algorithm reference document (Future enhancement)
  - `docs/ALGORITHMS.md`
  - Cosine similarity implementation
  - Connected components (DFS) implementation
  - CLIP preprocessing steps

---

## Definition of Done

- [x] Xcode 15+ installed and working ✅ Xcode 26.2, Swift 6.2.3
- [x] Can create and build iOS app project ✅ DuplicatePhotos.xcodeproj created
- [x] Git repository initialized with proper structure ✅ Complete
- [x] Python dependencies installed for model conversion ✅ coremltools 9.0
- [x] Git LFS configured for model files ✅ Tracking .mlmodel/.mlpackage
- [x] Python submodule added for reference ✅ Reference/duplicate-images
- [x] Documentation created ✅ README, CLAUDE.md, Epic docs

---

## Dependencies

**Blocks**:

- Epic 2 (CoreML Model) - needs Xcode and coremltools
- All other epics - need Xcode project structure

**Blocked By**:

- None

---

## Notes

- Xcode download is ~15GB, will take time depending on internet speed
- Git LFS is optional for MVP but highly recommended for model versioning
- Python submodule is read-only reference, not executed code
