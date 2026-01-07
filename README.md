# Duplicate Photos iOS 📸

A native iOS app for detecting and managing duplicate photos using on-device CoreML processing.

**Status**: 🔄 In Development (Phase 1)

---

## Features

- 🧠 **On-Device AI**: Uses CoreML for privacy-preserving duplicate detection
- 🎨 **Beautiful UI**: Native SwiftUI design matching iOS guidelines
- ⚡ **Fast**: Optimized similarity search with Accelerate framework
- 💾 **Smart Caching**: Avoids reprocessing with intelligent embedding cache
- 🔒 **Privacy First**: All processing happens on your device, no data leaves your phone
- 🎯 **Accurate**: Uses CLIP vision model for semantic similarity detection

---

## Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **ML Framework**: CoreML (converted from CLIP)
- **Architecture**: MVVM
- **Minimum iOS**: 17.0
- **Storage**: Core Data / SQLite for caching

---

## Project Status

### Current Phase: Phase 1 - Foundation (Week 1-2)

See [PROJECT_TRACKER.md](docs/PROJECT_TRACKER.md) for detailed progress.

| Epic | Status | Progress |
|------|--------|----------|
| 1. Project Setup | 🔄 In Progress | 0/3 tasks |
| 2. CoreML Model | ⏳ Pending | 0/2 tasks |
| 3. Core Services | ⏳ Pending | 0/4 tasks |
| 4. User Interface | ⏳ Pending | 0/5 tasks |
| 5. Architecture | ⏳ Pending | 0/2 tasks |
| 6. Testing & Polish | ⏳ Pending | 0/4 tasks |
| 7. Deployment | ⏳ Pending | 0/2 tasks |

---

## Setup

### Prerequisites

- **Xcode 15+** (from Mac App Store)
- **macOS Sonoma** (14.0+) or later
- **Apple Developer Account** (free tier works for development)
- **Python 3.8+** (for CLIP to CoreML conversion)

### Python Dependencies

For model conversion:
```bash
pip3 install coremltools transformers torch
```

### Installation

1. Clone this repository:
```bash
git clone [repo-url]
cd duplicate-photos-ios
```

2. Install Git LFS (for model files):
```bash
brew install git-lfs
git lfs install
```

3. Update submodules (Python reference):
```bash
git submodule update --init --recursive
```

4. Convert CLIP model to CoreML:
```bash
python3 scripts/convert_clip_to_coreml.py
```

5. Open in Xcode:
```bash
open DuplicatePhotos.xcodeproj
```

6. Build and run on simulator or device

---

## Project Structure

```
duplicate-photos-ios/
├── DuplicatePhotos/              # Main app target
│   ├── App/                      # App entry point
│   ├── Models/                   # Data models
│   ├── Views/                    # SwiftUI views
│   ├── ViewModels/               # MVVM view models
│   ├── Services/                 # Business logic
│   │   ├── EmbeddingService.swift
│   │   ├── SimilarityService.swift
│   │   ├── CacheService.swift
│   │   ├── PhotoLibraryService.swift
│   │   └── DuplicateDetector.swift
│   └── Resources/                # Assets, CoreML models
├── DuplicatePhotosTests/         # Unit tests
├── DuplicatePhotosUITests/       # UI tests
├── scripts/                      # Conversion scripts
│   └── convert_clip_to_coreml.py
├── docs/                         # Documentation
│   ├── PROJECT_TRACKER.md        # Main progress tracker
│   └── epics/                    # Individual epic files
└── Reference/                    # Python CLI (submodule)
    └── duplicate-images/         # Original Python implementation
```

---

## How It Works

1. **Photo Scanning**: Accesses user's photo library via PHPhotoLibrary
2. **Embedding Extraction**: Uses CoreML CLIP model to create 512-dimensional embeddings
3. **Caching**: Stores embeddings to avoid reprocessing
4. **Similarity Search**: Computes cosine similarity between all photo pairs
5. **Grouping**: Uses connected components algorithm (DFS) to group similar photos
6. **User Review**: Presents duplicate groups with merge/delete options

**Default Threshold**: 0.90 (configurable in settings)

---

## Development

### Architecture

This app follows **MVVM (Model-View-ViewModel)** architecture:

- **Models**: Data structures (PhotoAsset, DuplicateGroup, ScanSettings)
- **Views**: SwiftUI views (ScanView, DetailView, SettingsView)
- **ViewModels**: Business logic (ScanViewModel, GroupViewModel)
- **Services**: Core functionality (Detection, Caching, Photo Access)

### Algorithms

Based on the Python CLI implementation:

- **Cosine Similarity**: `dot(a, b) / (norm(a) * norm(b))`
- **Connected Components**: DFS-based graph traversal for grouping
- **Optimization**: Uses Accelerate framework (vDSP) for performance

See [Python Reference](Reference/duplicate-images/) for original implementation.

---

## Testing

Run tests in Xcode:
```bash
# Unit tests
cmd + U

# UI tests
cmd + U (with UI Tests selected)
```

**Coverage Target**: >70%

---

## Contributing

This is a personal project, but suggestions are welcome! Please open an issue to discuss proposed changes.

---

## Roadmap

### MVP (v1.0) - 8 weeks
- [x] Project setup
- [ ] CoreML model conversion
- [ ] Core duplicate detection
- [ ] Beautiful SwiftUI UI
- [ ] Merge/delete functionality
- [ ] TestFlight beta

### Post-MVP (v1.1+)
- [ ] Multiple CLIP model options
- [ ] Fine-grained threshold control
- [ ] Export duplicate report (CSV/JSON)
- [ ] iCloud Photos support
- [ ] iPad optimization
- [ ] Widgets
- [ ] Shortcuts app integration
- [ ] Video duplicate detection

---

## License

[MIT License](LICENSE) - See LICENSE file for details

---

## Acknowledgments

- Based on [duplicate-images](Reference/duplicate-images/) Python CLI
- Uses OpenAI's CLIP model for vision embeddings
- Inspired by iOS Photos app duplicate detection

---

## Support

- **Issues**: [GitHub Issues](issues)
- **Documentation**: [docs/](docs/)
- **Progress**: [PROJECT_TRACKER.md](docs/PROJECT_TRACKER.md)

---

Built with ❤️ using Swift and SwiftUI
