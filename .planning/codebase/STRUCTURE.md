# Codebase Structure

**Analysis Date:** 2026-01-27

## Directory Layout

```
/Users/Moshe.Avni/Repos/duplicate-photos-ios/
├── DuplicatePhotos/                          # Main application target
│   ├── App/                                  # Application entry point
│   │   └── DuplicatePhotosApp.swift          # @main app struct
│   ├── Models/                               # Data structures
│   │   ├── PhotoAsset.swift                  # Photo + embedding wrapper
│   │   ├── DuplicateGroup.swift              # Group of similar photos
│   │   ├── ScanSettings.swift                # Detection configuration
│   │   └── (CachedEmbedding)                 # Defined in CacheService.swift
│   ├── Services/                             # Business logic (actor-based)
│   │   ├── DuplicateDetector.swift           # Main orchestrator
│   │   ├── PhotoLibraryService.swift         # Photos framework wrapper
│   │   ├── EmbeddingService.swift            # CoreML model inference
│   │   ├── SimilarityService.swift           # Vector similarity + grouping
│   │   └── CacheService.swift                # Persistent embedding cache
│   ├── ViewModels/                           # UI state management
│   │   └── ScanViewModel.swift               # Scan progress + results
│   ├── Views/                                # SwiftUI user interface
│   │   ├── ContentView.swift                 # Home + nested ScanView
│   │   ├── DuplicateGroupsListView.swift     # Groups list + GroupCardView
│   │   └── GroupDetailView.swift             # Group details + PhotoThumbnailView
│   ├── Resources/                            # Assets and models
│   │   ├── Assets.xcassets/                  # App icon
│   │   ├── CLIPVision.mlpackage/             # CoreML model (generated)
│   │   └── Info.plist                        # App permissions & metadata
│
├── DuplicatePhotosTests/                     # Unit test target (empty)
├── DuplicatePhotosUITests/                   # UI test target (empty)
├── DuplicatePhotos.xcodeproj/                # Xcode project
├── docs/                                     # Project documentation
│   └── epics/                                # Feature epics
├── Reference/                                # Python reference (submodule)
├── scripts/                                  # Build/utility scripts
├── project.yml                               # XcodeGen project definition
├── CLAUDE.md                                 # AI assistant instructions
├── README.md                                 # Project overview
├── NEXT_STEPS.md                             # Implementation roadmap
└── .planning/                                # GSD planning directory
    └── codebase/                             # Architecture documentation
```

## Directory Purposes

**DuplicatePhotos/App:**
- Purpose: Application bootstrap and scene setup
- Contains: Single file with `@main` struct
- Key files: `DuplicatePhotosApp.swift`

**DuplicatePhotos/Models:**
- Purpose: Data structures representing domain concepts
- Contains: Swift value types (structs)
- Key files:
  - `PhotoAsset.swift`: Wraps PHAsset with embedding metadata
  - `DuplicateGroup.swift`: Collection of similar photos
  - `ScanSettings.swift`: Configuration for detection pipeline

**DuplicatePhotos/Services:**
- Purpose: Core business logic with actor-based concurrency safety
- Contains: Five actor-based services implementing the detection pipeline
- Key files:
  - `DuplicateDetector.swift`: Main orchestrator (72KB, ~150 lines)
  - `PhotoLibraryService.swift`: Photo library access (94 lines)
  - `EmbeddingService.swift`: CoreML model inference (99 lines)
  - `SimilarityService.swift`: Vector similarity computation (134 lines)
  - `CacheService.swift`: Persistent embedding cache (100 lines)

**DuplicatePhotos/ViewModels:**
- Purpose: UI state management and presentation logic
- Contains: Observable classes with `@Published` properties
- Key files: `ScanViewModel.swift` - connects UI to services

**DuplicatePhotos/Views:**
- Purpose: SwiftUI user interface components
- Contains: Structs implementing View protocol
- Key files:
  - `ContentView.swift`: Home screen + nested ScanView (175 lines)
  - `DuplicateGroupsListView.swift`: List of groups + card view (141 lines)
  - `GroupDetailView.swift`: Group details + photo grid (262 lines)

**DuplicatePhotos/Resources:**
- Purpose: Static assets and trained models
- Contains: Icon assets, Info.plist, CoreML model package
- Key files:
  - `Assets.xcassets/`: App icon (AppIcon.appiconset)
  - `CLIPVision.mlpackage/`: Converted CLIP vision model (~350MB)
  - `Info.plist`: App permissions and metadata

**docs/epics/:**
- Purpose: Feature planning and implementation tracking
- Contains: Epic documents for phases 1-7
- Uses: Markdown with checklist items

**DuplicatePhotosTests/ & DuplicatePhotosUITests/:**
- Purpose: Test targets for unit and UI testing
- Status: Created but empty (placeholder for future tests)

**Reference/:**
- Purpose: Python reference implementation (git submodule)
- Contains: `duplicate-images/` project with original ML pipeline

## Key File Locations

**Entry Points:**
- `DuplicatePhotos/App/DuplicatePhotosApp.swift`: App initialization (@main)
- `DuplicatePhotos/Views/ContentView.swift`: Home screen and navigation

**Configuration:**
- `DuplicatePhotos/Resources/Info.plist`: App metadata, permissions
- `DuplicatePhotos/Models/ScanSettings.swift`: Detection parameters
- `project.yml`: XcodeGen project definition (deployment target iOS 17.0, Swift 6.0)

**Core Logic:**
- `DuplicatePhotos/Services/DuplicateDetector.swift`: Main orchestrator
- `DuplicatePhotos/Services/EmbeddingService.swift`: CoreML inference
- `DuplicatePhotos/Services/SimilarityService.swift`: Similarity computation
- `DuplicatePhotos/Services/CacheService.swift`: Embedding persistence

**Presentation:**
- `DuplicatePhotos/ViewModels/ScanViewModel.swift`: UI state manager
- `DuplicatePhotos/Views/ContentView.swift`: Home + ScanView
- `DuplicatePhotos/Views/DuplicateGroupsListView.swift`: Results list
- `DuplicatePhotos/Views/GroupDetailView.swift`: Group detail page

**CoreML Model:**
- `DuplicatePhotos/Resources/CLIPVision.mlpackage/`: Generated model package
- Loaded at runtime: `Bundle.main.url(forResource: "CLIPVision", withExtension: "mlmodelc")`

## Naming Conventions

**Files:**
- Services: `[FunctionName]Service.swift` (e.g., `EmbeddingService.swift`, `PhotoLibraryService.swift`)
- Models: `[EntityName].swift` (e.g., `PhotoAsset.swift`, `DuplicateGroup.swift`)
- ViewModels: `[ViewName]ViewModel.swift` (e.g., `ScanViewModel.swift`)
- Views: `[ViewName]View.swift` (e.g., `ContentView.swift`, `GroupDetailView.swift`)
- Helpers in Views: `[ComponentName]View.swift` (e.g., `GroupCardView`, `PhotoThumbnailView`, nested in same file)

**Directories:**
- Domain layer: lowercase plural (e.g., `models/`, `services/`, `views/`, `viewmodels/`)
- App structure: `App/`, `Resources/`, `docs/`

**Types:**
- Services: `[Name]Service` (actor)
- Models: `[Name]` (struct)
- ViewModels: `[Name]ViewModel` (@MainActor class)
- Views: `[Name]View` (struct implementing View)
- Enums (errors): `[ServiceName]Error` (e.g., `PhotoLibraryError`, `EmbeddingError`)

**Properties & Functions:**
- Property naming: camelCase, descriptive (e.g., `isScanning`, `duplicateGroups`, `progressValue`)
- Function naming: camelCase, verb-based (e.g., `startScan()`, `loadImage()`, `extractEmbedding()`)
- Private/internal: `private func`, `private var`, no prefix convention

## Where to Add New Code

**New Feature (e.g., merge photos):**
- Primary code: `DuplicatePhotos/Services/` → new actor (e.g., `MergeService.swift`)
- ViewModel updates: `DuplicatePhotos/ViewModels/ScanViewModel.swift` → add `@Published` state and method
- View updates: `DuplicatePhotos/Views/GroupDetailView.swift` → add button/action
- Integration: Update `DuplicateDetector` if coordination needed

**New Component/Module:**
- SwiftUI view: `DuplicatePhotos/Views/[ComponentName]View.swift`
- Supporting model: `DuplicatePhotos/Models/[DataStructure].swift`
- Service logic: `DuplicatePhotos/Services/[Logic]Service.swift`
- ViewModel state: Add to existing `ScanViewModel` or create new if managing separate feature

**Utilities/Helpers:**
- Shared extensions: Create `DuplicatePhotos/Utilities/[Name]+Extension.swift`
- Reusable views: `DuplicatePhotos/Views/Components/[ComponentName]View.swift` (if needed)
- Algorithm helpers: Keep in relevant service or create `DuplicatePhotos/Utilities/Algorithms.swift`

**Tests:**
- Unit tests: `DuplicatePhotosTests/[TargetFile]Tests.swift`
- UI tests: `DuplicatePhotosUITests/[FeatureName]UITests.swift`
- Test data: `DuplicatePhotosTests/Fixtures/` (if needed)

## Special Directories

**DuplicatePhotos/Resources/CLIPVision.mlpackage/:**
- Purpose: CoreML model package (compiled model + metadata)
- Generated: Yes (from Python script during setup)
- Committed: Yes (large, tracked via Git LFS per `.gitattributes`)
- Size: ~350MB
- Usage: Loaded by `EmbeddingService` on first embedding request
- Format: MLModel format with Vision framework compatibility

**~/.cache/DuplicatePhotos/:**
- Purpose: Runtime cache directory for persistent embeddings
- Generated: Yes (created on first app run)
- Committed: No (user data, transient)
- Contents: `embeddings_cache.json` (JSON array of CachedEmbedding objects)

**docs/epics/:**
- Purpose: Project planning and progress tracking
- Generated: No (hand-written)
- Committed: Yes (part of project documentation)
- Files: `epic-[1-7]-[feature].md` for each major phase

**DuplicatePhotosTests/ & DuplicatePhotosUITests/:**
- Purpose: Test targets
- Generated: No (empty placeholders)
- Committed: Yes (directory structure)
- Future: Will contain test cases as coverage increases

## Architecture-Specific Notes

**Actor-Based Concurrency:**
- All services are actors to prevent data races
- Services communicate via async/await, never sync calls
- ViewModels are `@MainActor` to ensure UI thread safety
- Progress callbacks use `@Sendable` closures

**Navigation:**
- Root: `NavigationStack` in `ContentView`
- Paths: NavigationLink destinations to `ScanView`, `DuplicateGroupsListView`, `GroupDetailView`
- Dismissal: Automatic on group deletion via `@Environment(\.dismiss)`

**State Management:**
- Global service state: Managed by actors (DuplicateDetector, CacheService)
- UI state: Managed by `ScanViewModel` with `@Published` properties
- View state: Local `@State` for selection, modals, forms
- No external state management library (built-in SwiftUI patterns)

---

*Structure analysis: 2026-01-27*
