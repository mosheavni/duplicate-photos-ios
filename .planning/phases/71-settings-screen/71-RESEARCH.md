# Phase 71: Settings Screen - Research

**Researched:** 2026-01-27
**Domain:** SwiftUI Settings UI & Persistence
**Confidence:** HIGH

## Summary

Settings screens in SwiftUI follow established patterns using Form containers for data entry, @AppStorage for automatic UserDefaults persistence, and standard iOS navigation patterns. The iOS ecosystem has well-defined conventions for settings UI that users expect.

For this phase, the standard approach is to use Form (not List) for the settings layout, @AppStorage property wrappers for automatic persistence of the similarity threshold, and native SwiftUI components (Slider, Button, Text) for controls. Navigation can be either NavigationLink (push) or sheet (modal), with NavigationLink being more common for settings in primary navigation flow.

The similarity threshold will be stored in UserDefaults using @AppStorage, which provides automatic two-way binding and eliminates manual synchronization code. Cache management requires calling existing CacheService methods. Version information is retrieved from Bundle.main.infoDictionary. Confirmation dialogs use the .confirmationDialog() modifier introduced in iOS 15.

**Primary recommendation:** Use Form with @AppStorage for threshold persistence, NavigationLink from toolbar gear icon for navigation, and native confirmationDialog for destructive actions.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | UI framework | Native Apple framework, declarative UI |
| UserDefaults | iOS 17+ | Settings persistence | Built-in key-value storage, @AppStorage integration |
| Foundation Bundle | iOS 17+ | App version retrieval | Standard iOS app metadata access |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Combine | iOS 17+ | Reactive updates | Already used by @AppStorage internally |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Form | List | Form provides better styling for settings on iOS/macOS, List is for data presentation |
| @AppStorage | Manual UserDefaults | @AppStorage provides automatic UI updates, less boilerplate |
| NavigationLink | sheet() | Sheet for modal/unrelated content, NavigationLink for hierarchical settings navigation |

**Installation:**
None required - all components are part of iOS SDK.

## Architecture Patterns

### Recommended Project Structure
```
DuplicatePhotos/
├── Views/
│   ├── SettingsView.swift      # Main settings screen
│   └── ContentView.swift        # Add toolbar with gear icon
└── Models/
    └── ScanSettings.swift       # Extend to read from UserDefaults
```

### Pattern 1: Form-Based Settings Layout
**What:** Use Form container with Section groups for organizing settings controls
**When to use:** Any iOS settings screen with user input controls
**Example:**
```swift
// Source: Multiple SwiftUI community patterns
Form {
    Section("Similarity Threshold") {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Threshold")
                Spacer()
                Text("\(Int(threshold * 100))%")
                    .foregroundStyle(.secondary)
            }
            Slider(value: $threshold, in: 0.85...0.98, step: 0.01)
            Text("Higher = stricter matching, fewer results")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    Section("Cache Management") {
        HStack {
            Text("Cached Photos")
            Spacer()
            Text("\(cachedCount)")
                .foregroundStyle(.secondary)
        }

        Button("Clear Cache", role: .destructive) {
            showClearConfirmation = true
        }
    }

    Section("About") {
        LabeledContent("Version", value: appVersion)
        LabeledContent("Build", value: buildNumber)
    }

    Section {
        Button("Reset to Defaults") {
            threshold = 0.92
        }
    }
}
.navigationTitle("Settings")
```

### Pattern 2: AppStorage for Auto-Persistence
**What:** Use @AppStorage property wrapper for automatic UserDefaults synchronization
**When to use:** Settings that need persistence and automatic UI updates
**Example:**
```swift
// Source: SwiftUI documentation patterns
struct SettingsView: View {
    @AppStorage("similarityThreshold") private var threshold: Double = 0.92

    var body: some View {
        Form {
            Slider(value: $threshold, in: 0.85...0.98)
        }
    }
}

// ScanSettings reads from same UserDefaults key
struct ScanSettings {
    var similarityThreshold: Float {
        Float(UserDefaults.standard.double(forKey: "similarityThreshold"))
    }
}
```

### Pattern 3: Toolbar Navigation to Settings
**What:** Add gear icon button in NavigationStack toolbar
**When to use:** Settings accessible from main screen
**Example:**
```swift
// Source: SwiftUI navigation patterns
NavigationStack {
    MainContentView()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                }
            }
        }
}
```

### Pattern 4: Confirmation Dialog for Destructive Actions
**What:** Use .confirmationDialog() modifier for confirming cache clear
**When to use:** Any destructive or irreversible action
**Example:**
```swift
// Source: iOS 15+ confirmationDialog API
Button("Clear Cache", role: .destructive) {
    showClearConfirmation = true
}
.confirmationDialog(
    "Clear Cache?",
    isPresented: $showClearConfirmation,
    titleVisibility: .visible
) {
    Button("Clear Cache", role: .destructive) {
        Task {
            await clearCache()
            showSuccessToast = true
        }
    }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("This will remove all cached embeddings. Your next scan will take longer.")
}
```

### Pattern 5: App Version Display
**What:** Retrieve version and build from Bundle.main.infoDictionary
**When to use:** About section in settings
**Example:**
```swift
// Source: Standard iOS version retrieval pattern
var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
}

var buildNumber: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
}
```

### Anti-Patterns to Avoid
- **Using List instead of Form:** List is for data display, Form provides proper styling for settings input controls
- **Manual UserDefaults.standard.set():** Use @AppStorage instead for automatic UI synchronization
- **@State for persisted settings:** @State doesn't persist, use @AppStorage for settings that survive app restarts
- **sheet() for settings navigation:** Use NavigationLink for hierarchical settings that are part of main navigation flow
- **Forgetting .confirmationDialog() for destructive actions:** Always confirm destructive actions like cache clearing

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Settings persistence | Custom file I/O or Core Data | @AppStorage + UserDefaults | Automatic UI sync, thread-safe, system-managed |
| Slider with percentage display | Custom slider implementation | Native Slider + Text | Accessibility, standard gestures, VoiceOver support |
| Version number retrieval | Hard-coded strings | Bundle.main.infoDictionary | Auto-updated on build, single source of truth |
| Destructive action confirmation | Custom alert views | .confirmationDialog() | Standard iOS patterns, accessibility built-in |
| Toast notifications | Custom overlay views | Simple @State + opacity animation | For MVP - complex toast libs add unnecessary dependencies |

**Key insight:** SwiftUI provides native components optimized for iOS. Custom implementations lose accessibility features, VoiceOver support, and future iOS updates. UserDefaults is thread-safe and handles synchronization automatically - don't reimplement persistence.

## Common Pitfalls

### Pitfall 1: Type Mismatch Between @AppStorage and Model
**What goes wrong:** @AppStorage uses Double for slider, but ScanSettings.similarityThreshold is Float
**Why it happens:** Swift requires explicit type conversions between Float and Double
**How to avoid:** Store as Double in @AppStorage, convert to Float when creating ScanSettings
**Warning signs:** Compile error "Cannot convert value of type 'Double' to expected argument type 'Float'"

### Pitfall 2: Writing to UserDefaults from Non-Main Thread
**What goes wrong:** App crashes or data corruption when writing UserDefaults from background threads with @AppStorage in use
**Why it happens:** @AppStorage uses KVO to observe UserDefaults, making writes from background threads unsafe
**How to avoid:** Always update @AppStorage-bound values on MainActor or main thread
**Warning signs:** Intermittent crashes in UserDefaults setValue, KVO observer crashes

### Pitfall 3: Forgetting Default Value Handling
**What goes wrong:** App crashes or shows 0.0 threshold on first launch when no value stored yet
**Why it happens:** UserDefaults returns 0 for unset keys, not the default value
**How to avoid:** Always provide default value in @AppStorage declaration: `@AppStorage("key") var value: Double = 0.92`
**Warning signs:** First launch shows wrong threshold, settings reset unexpectedly

### Pitfall 4: Not Showing Confirmation Before Destructive Actions
**What goes wrong:** Users accidentally clear cache, causing long re-scan
**Why it happens:** Button tap triggers action immediately without confirmation
**How to avoid:** Use .confirmationDialog() modifier with role: .destructive on buttons
**Warning signs:** User complaints about accidental data loss, no undo mechanism

### Pitfall 5: Missing Explanatory Text for Threshold Slider
**What goes wrong:** Users don't understand what threshold values mean, set inappropriate values
**Why it happens:** Slider alone doesn't explain the tradeoff between strict/loose matching
**How to avoid:** Add explanatory Text with .font(.caption) below slider
**Warning signs:** Support questions about "why am I getting too many/few results?"

### Pitfall 6: Cache Count Not Updating After Clear
**What goes wrong:** Cache count still shows old value after clearing
**Why it happens:** View doesn't refresh after async cache clear operation
**How to avoid:** Use @State for cache count, update it after clearing with Task/@MainActor
**Warning signs:** UI shows stale data, requires app restart to see correct count

## Code Examples

Verified patterns from official sources:

### Complete SettingsView Structure
```swift
// Source: Composite of SwiftUI best practices
struct SettingsView: View {
    @AppStorage("similarityThreshold") private var threshold: Double = 0.92
    @State private var cachedCount: Int = 0
    @State private var showClearConfirmation = false
    @State private var showSuccessToast = false

    private let cacheService = CacheService()

    var body: some View {
        Form {
            thresholdSection
            cacheSection
            aboutSection
            resetSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCacheStats()
        }
        .overlay(alignment: .top) {
            if showSuccessToast {
                toastView
            }
        }
    }

    private var thresholdSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Similarity Threshold")
                    Spacer()
                    Text("\(Int(threshold * 100))%")
                        .foregroundStyle(.secondary)
                }

                Slider(value: $threshold, in: 0.85...0.98, step: 0.01)

                Text("Higher = stricter matching, fewer results")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Detection")
        }
    }

    private var cacheSection: some View {
        Section {
            LabeledContent("Cached Photos", value: "\(cachedCount)")

            Button("Clear Cache", role: .destructive) {
                showClearConfirmation = true
            }
        } header: {
            Text("Cache")
        }
        .confirmationDialog(
            "Clear Cache?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Cache", role: .destructive) {
                Task {
                    await clearCache()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all cached embeddings. Your next scan will take longer.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: appVersion)
            LabeledContent("Build", value: buildNumber)
            LabeledContent("Credits", value: "Built with CoreML")
        }
    }

    private var resetSection: some View {
        Section {
            Button("Reset to Defaults") {
                threshold = 0.92
            }
        }
    }

    private var toastView: some View {
        Text("Cache cleared successfully")
            .padding()
            .background(.thinMaterial)
            .cornerRadius(10)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation {
                        showSuccessToast = false
                    }
                }
            }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    private func loadCacheStats() async {
        let (count, _) = await cacheService.getCacheStats()
        await MainActor.run {
            cachedCount = count
        }
    }

    private func clearCache() async {
        await cacheService.clearCache()
        await loadCacheStats()
        await MainActor.run {
            withAnimation {
                showSuccessToast = true
            }
        }
    }
}
```

### Updating ScanSettings to Read from UserDefaults
```swift
// Source: Standard UserDefaults integration pattern
struct ScanSettings {
    var similarityThreshold: Float {
        // Read from same key as @AppStorage
        let stored = UserDefaults.standard.double(forKey: "similarityThreshold")
        // Return default if not set (0.0 means unset)
        return stored > 0 ? Float(stored) : 0.92
    }

    var batchSize: Int = 100
    var useCaching: Bool = true
    var includeVideos: Bool = false

    static let `default` = ScanSettings()
}
```

### Adding Toolbar Button to ContentView
```swift
// Source: SwiftUI NavigationStack toolbar patterns
struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // ... existing content ...

                NavigationLink(destination: ScanView()) {
                    Label("Start Scan", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.gradient)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Duplicate Photos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| UserDefaults.standard.set() | @AppStorage property wrapper | iOS 14 (2020) | Automatic UI updates, less boilerplate |
| .actionSheet() | .confirmationDialog() | iOS 15 (2021) | Better positioning (bottom on iOS), clearer API |
| NavigationView | NavigationStack | iOS 16 (2022) | Better programmatic navigation, cleaner API |
| Manual synchronize() | Automatic persistence | iOS 7+ | No need to call synchronize(), happens automatically |

**Deprecated/outdated:**
- UserDefaults.synchronize(): No longer needed in modern iOS, UserDefaults auto-saves periodically
- ActionSheet: Soft deprecated in iOS 15, use confirmationDialog() instead
- NavigationView: Replaced by NavigationStack/NavigationSplitView in iOS 16+

## Open Questions

Things that couldn't be fully resolved:

1. **Toast vs Alert for Success Message**
   - What we know: User wants toast/success message after cache clear
   - What's unclear: Whether to use simple custom animation or add toast library dependency
   - Recommendation: Use simple custom view with opacity animation for MVP (shown in code example above). Can upgrade to library later if more toast patterns needed.

2. **Settings Accessibility During Scan**
   - What we know: User wants settings accessible from main screen, scan access is Claude's discretion
   - What's unclear: Whether to allow threshold changes during active scan
   - Recommendation: Allow navigation to settings during scan, but disable threshold slider with .disabled(viewModel.isScanning) to prevent mid-scan changes that could cause inconsistent results.

3. **Cache Stats Update Frequency**
   - What we know: Cache stats should show current count
   - What's unclear: Whether to update live as scan progresses or only on view appear
   - Recommendation: Update on .task (view appear) and after clear action. Live updates during scan would require publisher/observer pattern - unnecessary complexity for MVP.

## Sources

### Primary (HIGH confidence)
- [Apple SwiftUI Settings Documentation](https://developer.apple.com/documentation/swiftui/settings) - Official SwiftUI settings scene API
- [Apple AppStorage Documentation](https://developer.apple.com/documentation/swiftui/appstorage) - Official @AppStorage property wrapper
- [Apple Slider Documentation](https://developer.apple.com/documentation/swiftui/slider) - Official Slider component
- [Apple Confirmation Dialog Documentation](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:presenting:actions:)-9ibgk) - Official dialog API
- [SwiftUI Form Tutorial](https://medium.com/@sharma17krups/swiftui-form-tutorial-how-to-create-settings-screen-using-form-part-1-8e8e80cf584e) - Form best practices
- [Holy Swift - AppStorage Tutorial](https://holyswift.app/using-userdefaults-to-persist-in-swiftui/) - @AppStorage implementation patterns

### Secondary (MEDIUM confidence)
- [Hacking with Swift - What is @AppStorage](https://www.hackingwithswift.com/quick-start/swiftui/what-is-the-appstorage-property-wrapper) - Property wrapper explanation
- [Medium - UserDefaults vs @AppStorage](https://medium.com/@nsuneelkumar98/swiftui-data-persistence-userdefaults-vs-appstorage-a66c41666d15) - Comparison and when to use each
- [Swift Anytime - Slider in SwiftUI](https://www.swiftanytime.com/blog/slider-in-swiftui) - Slider implementation patterns
- [Use Your Loaf - Confirmation Dialogs](https://useyourloaf.com/blog/swiftui-confirmation-dialogs/) - Dialog best practices
- [Hacking with Swift - Navigation Bar Buttons](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-bar-items-to-a-navigation-view) - Toolbar button patterns

### Secondary (MEDIUM confidence) - Verification Sources
- [Medium - App Version Display](https://blog.rampatra.com/how-to-display-the-app-version-in-a-macos-ios-swiftui-app) - Bundle info retrieval
- [Sarunw - Reading Info.plist](https://sarunw.com/posts/how-to-read-info-plist/) - Version number best practices
- [Medium - UserDefaults Thread Safety](https://medium.com/@omar.saibaa/local-storage-in-ios-userdefaults-51ec4601add1) - UserDefaults threading considerations
- [Apple Developer Forums - AppStorage Thread Safety](https://developer.apple.com/forums/thread/698840) - Known AppStorage/UserDefaults threading issues

### Tertiary (LOW confidence)
- [Swiftyplace - Form vs List](https://www.swiftyplace.com/blog/swiftui-form-add-settings-view-ios) - When to use each container
- [Medium - SwiftUI Common Mistakes 2025](https://medium.com/@garejakirit/common-mistakes-beginners-make-in-swiftui-and-how-to-fix-them-5a4a6d48701e) - Current pitfalls
- [Hacking with Swift - 8 Common Mistakes](https://www.hackingwithswift.com/articles/224/common-swiftui-mistakes-and-how-to-fix-them) - General SwiftUI pitfalls

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All components are native iOS SDK with official documentation
- Architecture: HIGH - Patterns verified across official docs and multiple authoritative sources
- Pitfalls: MEDIUM - Thread safety issues documented in forums, some patterns from experience

**Research date:** 2026-01-27
**Valid until:** 2026-02-27 (30 days - stable iOS SDK domain, unlikely to change)
