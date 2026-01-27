# External Integrations

**Analysis Date:** 2026-01-27

## APIs & External Services

**No External APIs** - This application does not integrate with any third-party APIs or cloud services. All processing is on-device.

## Data Storage

**Photo Library:**
- Provider: Apple Photos framework (PHPhotoLibrary)
- Access method: `DuplicatePhotos/Services/PhotoLibraryService.swift`
- Functionality:
  - Read access to user's photo library
  - Asset fetching via PHAsset.fetchAssets()
  - Image loading via PHImageManager
  - Delete capability via PHAssetChangeRequest
- No external data sent to cloud

**Embedding Cache:**
- Storage: Local filesystem only
- Location: `~/Library/Caches/DuplicatePhotos/embeddings_cache.json`
- Serialization: JSON (native Swift Codable)
- Persistence: JSONEncoder/JSONDecoder in `DuplicatePhotos/Services/CacheService.swift`
- No cloud sync or backup

## Machine Learning Model

**CoreML Model:**
- Model: CLIPVision CLIP Vision
- Format: `.mlpackage` (compiled to `.mlmodelc`)
- Location: `DuplicatePhotos/Resources/CLIPVision.mlpackage/Data/com.apple.CoreML/model.mlmodel`
- Execution: On-device via CoreML inference
- No model updates from remote source
- No telemetry or data transmission

## Authentication & Identity

**Authorization Method:**
- Type: System-level photo library permissions
- Implementation: `PHPhotoLibrary.requestAuthorization(for: .readWrite)`
- Located in: `DuplicatePhotos/Services/PhotoLibraryService.swift`
- Status checking: `PHPhotoLibrary.authorizationStatus(for: .readWrite)`
- No user authentication or identity provider
- No login/account system

**Permission Types:**
- Photo library read access (required for scanning)
- Photo library write access (required for deleting duplicates)
- Permissions declared in `DuplicatePhotos/Info.plist`

## Monitoring & Observability

**Error Tracking:**
- None - No error reporting service integrated
- Error handling: Local error enums and Swift error protocol
- Logging: Print statements only (debug output to console)

**Logs:**
- Approach: Debug print statements (no persistent logging)
- Examples in:
  - `DuplicatePhotos/Services/EmbeddingService.swift` - Model loading, embedding extraction progress
  - `DuplicatePhotos/Services/SimilarityService.swift` - Similarity computation logging
  - `DuplicatePhotos/Services/PhotoLibraryService.swift` - Asset fetching status

**Telemetry:**
- None - No analytics, telemetry, or usage tracking

## CI/CD & Deployment

**Hosting:**
- Distribution: Apple TestFlight (planned) and App Store (planned)
- No cloud hosting required for application runtime
- Development: Local Xcode builds only

**CI Pipeline:**
- None configured currently
- Build system: Xcode (xcodebuild) via project.yml
- No GitHub Actions, Jenkins, or other CI service integration

**Deployment Target:**
- Platform: iOS 17.0+
- Device families: iPhone and iPad
- Manual deployment via Xcode Archive → TestFlight → App Store (process not yet automated)

## Environment Configuration

**Required Environment Variables:**
- None - Application uses no environment-specific configuration
- All settings hardcoded or stored locally:
  - Similarity threshold: `ScanSettings.swift` (default 0.90)
  - Caching enabled: Controlled via `useCaching` in `ScanSettings.swift`
  - Model path: Hardcoded to `Bundle.main.url(forResource: "CLIPVision", withExtension: "mlmodelc")`

**Configuration Storage:**
- `DuplicatePhotos/Models/ScanSettings.swift` - Scan behavior settings
  - Similarity threshold (default: 0.90)
  - Caching toggle (default: true)

**Secrets Location:**
- Not applicable - No API keys, credentials, or secrets
- No external authentication required

## Webhooks & Callbacks

**Incoming Webhooks:**
- None - Application does not expose any web endpoints
- Standalone iOS app with no network listening

**Outgoing Webhooks:**
- None - Application does not make outbound HTTP requests
- No data transmission to external services

## Data Flow & Network

**Network Connectivity:**
- Required: No
- Optional: For iCloud photo syncing (handled by OS, not by app)
- All duplicate detection processing is offline

**Data Transmission:**
- None - All data remains on-device
- Photo embeddings are generated locally
- Cache is stored locally
- No cloud backup or sync

## System Permissions

**Required Permissions (declared in Info.plist):**
- `NSPhotoLibraryUsageDescription`: "We need access to your photos to detect duplicates"
- `NSPhotoLibraryAddUsageDescription`: "We need access to modify your photo library to merge duplicates"

**Runtime Permission Checks:**
- `PhotoLibraryService.requestAuthorization()` - Handles permission request flow
- Supports limited photo library access (iOS 14+)
- Falls back gracefully on access denial

## Third-Party Integrations

**Summary:**
- **Count: 0** - This is a completely self-contained application
- **Cloud Dependencies: 0**
- **API Dependencies: 0**
- **External Service Dependencies: 0**

All functionality is implemented using only Apple's native frameworks and on-device processing.

---

*Integration audit: 2026-01-27*
