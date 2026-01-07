# Next Steps for Duplicate Photos iOS

## Current Status

✅ **Phase 1 Foundation: 95% Complete**

### Completed
- [x] Xcode project created (DuplicatePhotos.xcodeproj)
- [x] Full MVVM architecture implemented
- [x] All core services created (5/5)
- [x] Models defined
- [x] Basic UI structure
- [x] Git LFS configured
- [x] Python reference added as submodule
- [x] CoreML placeholder model created

### Pending
- [ ] Install iOS 26.2 SDK in Xcode
- [ ] Convert real CLIP model (requires Python 3.10-3.12)
- [ ] Complete UI implementation
- [ ] Build and test on simulator/device

---

## Immediate Actions

### 1. Open Project in Xcode
```bash
open DuplicatePhotos.xcodeproj
```

When Xcode opens:
- Configure your Development Team in project settings
- Xcode may prompt to download iOS 26.2 SDK - accept
- Select a simulator or connected device as build destination

### 2. First Build
- Press `⌘R` or click the Play button
- If prompted about code signing, select "Automatically manage signing"
- App should build and launch in simulator

### 3. Expected Behavior (with placeholder model)
- ✅ App launches successfully
- ✅ UI displays "Duplicate Photos" screen
- ✅ Photo library permission can be requested
- ⚠️ Scanning will return random duplicate groups (not functional)

---

## Converting Real CLIP Model

The placeholder model allows development but doesn't perform real duplicate detection.

### Option 1: Use Python 3.12 with asdf
```bash
# Switch to Python 3.12
asdf install python 3.12.8
asdf global python 3.12.8

# Install dependencies
pip3 install coremltools transformers torch

# Run conversion (~5 minutes, downloads ~1GB model)
python3 scripts/convert_clip_to_coreml.py
```

### Option 2: Use Python 3.11 via Homebrew
```bash
brew install python@3.11
python3.11 -m pip install coremltools transformers torch
python3.11 scripts/convert_clip_to_coreml.py
```

### After Conversion
- Real model will be at `DuplicatePhotos/Resources/CLIPVision.mlpackage`
- Rebuild the app in Xcode
- Duplicate detection will now work correctly

---

## Development Workflow

### Making Code Changes
1. Edit Swift files in Xcode or your preferred editor
2. Build with `⌘B` to check for compile errors
3. Run with `⌘R` to test on simulator

### Testing Photo Library Access
1. In simulator: Photos app > Add sample photos
2. Run DuplicatePhotos app
3. Grant photo library access when prompted
4. Test scan functionality

### Viewing Logs
- Xcode Console: `⌘⇧Y` to show/hide debug area
- Console app: View simulator logs in real-time

---

## Project Structure

```
DuplicatePhotos/
├── App/
│   └── DuplicatePhotosApp.swift        # Entry point (@main)
│
├── Models/
│   ├── PhotoAsset.swift                # Photo + embedding
│   ├── DuplicateGroup.swift            # Similar photo groups
│   └── ScanSettings.swift              # Configuration (threshold: 0.90)
│
├── Services/
│   ├── PhotoLibraryService.swift       # PHPhotoLibrary access
│   ├── EmbeddingService.swift          # CoreML CLIP wrapper
│   ├── SimilarityService.swift         # Cosine similarity (Accelerate)
│   ├── CacheService.swift              # Embedding persistence
│   └── DuplicateDetector.swift         # Main scan pipeline
│
├── ViewModels/
│   └── ScanViewModel.swift             # Scan state management
│
├── Views/
│   └── ContentView.swift               # Main UI
│
└── Resources/
    ├── Assets.xcassets/                # App icon, colors
    └── CLIPVision.mlpackage/           # ML model (placeholder)
```

---

## Key Files for Development

### Adding New Views
- Create in `DuplicatePhotos/Views/`
- Import SwiftUI
- Use `@ObservedObject` for ViewModels

### Adding New Services
- Create in `DuplicatePhotos/Services/`
- Use `actor` for thread-safe services
- Use `async/await` for I/O operations

### Modifying Scan Logic
- Edit `DuplicateDetector.swift` for pipeline changes
- Edit `SimilarityService.swift` for grouping algorithm
- Edit `ScanSettings.swift` for configuration

---

## Common Tasks

### Change Similarity Threshold
```swift
// In ScanSettings.swift
var similarityThreshold: Float = 0.90  // Change this value
```

### Add Progress Reporting
- Already implemented in `DuplicateDetector.scanForDuplicates`
- Use `progress` callback in ViewModels

### Clear Cache
```swift
await detector.clearCache()
```

---

## Troubleshooting

### "iOS 26.2 is not installed"
- Open Xcode > Settings > Platforms
- Download iOS 26.2 SDK
- Or select a different deployment target in project settings

### "Code signing requires a development team"
- Xcode > Project Settings > Signing & Capabilities
- Select your Apple ID team
- Enable "Automatically manage signing"

### "No such module 'CoreML'"
- Ensure deployment target is iOS 17.0+
- Clean build folder: `⌘⇧K`
- Rebuild: `⌘B`

### Placeholder Model Issues
- Expected: Duplicate detection won't work correctly
- Solution: Convert real CLIP model with Python 3.10-3.12

---

## Documentation

- Project overview: `README.md`
- Development guidance: `CLAUDE.md`
- Epic tracking: `docs/epics/`
- Progress tracking: `docs/PROJECT_TRACKER.md`
- Script documentation: `scripts/README.md`

---

## Getting Help

### Build Errors
1. Clean build folder: `⌘⇧K`
2. Check error messages in Xcode
3. Verify all Swift files are in project (Project Navigator)

### Runtime Errors
1. Check Xcode console for error messages
2. Verify photo library permissions granted
3. Check if using placeholder vs real model

### Python Conversion Issues
- See `scripts/README.md`
- Ensure using Python 3.10, 3.11, or 3.12
- Check PyTorch and coremltools versions

---

## What's Next

Once the project builds successfully:

1. **Complete UI** (Epic 4)
   - Scan progress view
   - Duplicate groups list
   - Group detail view
   - Settings screen

2. **Add Features**
   - Photo deletion
   - Merge duplicates
   - Export reports
   - Cache management

3. **Testing** (Epic 6)
   - Unit tests for services
   - UI tests
   - Performance testing
   - Edge case handling

4. **Polish** (Epic 7)
   - App icon
   - Launch screen
   - Animations
   - Error handling

5. **TestFlight Beta**
   - App Store Connect setup
   - Beta testing
   - User feedback

---

**Ready to build!** 🚀

Start by opening the project in Xcode:
```bash
open DuplicatePhotos.xcodeproj
```
