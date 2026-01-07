# Epic 1: Project Setup & Environment 🏗️

**Status**: 🔄 In Progress
**Phase**: 1 - Foundation
**Duration**: 2-3 days

---

## Overview
Set up the development environment and create the iOS project structure with proper tooling and configuration.

---

## Tasks

### Task 1.1: Development Environment Setup

**Status**: 🔄 In Progress

#### Required Installations:
- [ ] **Xcode 15+** (from Mac App Store)
  - ~15GB download
  - Includes Swift compiler, SwiftUI, iOS Simulator
- [ ] **Apple Developer Account** (free tier works)
  - Sign in at developer.apple.com
  - Configure in Xcode preferences
- [ ] **Command Line Tools**: ✅ Already installed
  - ~~`xcode-select --install`~~

#### Python Dependencies for Model Conversion:
- [ ] **coremltools**: `pip3 install coremltools`
  - Python: ✅ 3.14.0 (already installed)
  - PyTorch: ✅ 2.9.1 (already installed)
  - Transformers: ✅ 4.57.3 (already installed)
- [ ] **Git LFS**: `brew install git-lfs && git lfs install`
  - For managing large model files (~350MB)

#### Verification:
```bash
# After installations, verify:
xcodebuild -version           # Should show Xcode 15+
swift --version               # Should show Swift 5.9+
pip3 list | grep coremltools  # Should show version
git lfs version               # Should show installed
```

---

### Task 1.2: Create New iOS Project Repository

**Status**: ⏳ Pending

#### Repository Structure:
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

#### Subtasks:
- [ ] Create new Xcode project
  - File → New → Project
  - iOS → App
  - Interface: SwiftUI
  - Language: Swift
  - Save to: `~/Repos/duplicate-photos-ios/`
- [ ] Initialize Git repository
  - `git init`
  - Create first commit
- [ ] Set up .gitignore
  - Use Xcode template
  - Add: `*.mlmodel` (will use Git LFS)
  - Add: `.DS_Store`, `*.xcuserstate`
- [ ] Configure Git LFS for .mlmodel files
  - `git lfs track "*.mlmodel"`
  - `git add .gitattributes`
- [ ] Create README.md with:
  - Project description
  - Setup instructions
  - Development status
- [ ] Add LICENSE
  - MIT or same as Python repo

---

### Task 1.3: Add Python CLI as Git Submodule

**Status**: ⏳ Pending

#### Purpose:
Keep reference to original Python implementation for algorithm comparison and porting.

#### Subtasks:
- [ ] Add Python repo as submodule
  ```bash
  cd ~/Repos/duplicate-photos-ios
  git submodule add [python-repo-url] Reference/duplicate-images
  git submodule update --init --recursive
  ```
- [ ] Document Python → Swift mapping
  - Create `docs/PYTHON_TO_SWIFT.md`
  - Map each Python file to planned Swift file
  - Document algorithm translations
- [ ] Create algorithm reference document
  - `docs/ALGORITHMS.md`
  - Cosine similarity implementation
  - Connected components (DFS) implementation
  - CLIP preprocessing steps

---

## Definition of Done

- [ ] Xcode 15+ installed and working
- [ ] Can create and build iOS app project
- [ ] Git repository initialized with proper structure
- [ ] Python dependencies installed for model conversion
- [ ] Git LFS configured for model files
- [ ] Python submodule added for reference
- [ ] Documentation created

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
