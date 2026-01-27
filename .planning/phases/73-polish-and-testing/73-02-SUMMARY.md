---
phase: 73-polish-and-testing
plan: 02
subsystem: ui-polish
completed: 2026-01-27
duration: 3min
tags: [ios17, swiftui, empty-states, permissions, ux]

requires:
  - 72-batch-operations
provides:
  - native-empty-states
  - permission-error-handling
  - settings-deep-link
affects:
  - future-ui-enhancements

tech-stack:
  added: []
  patterns:
    - ContentUnavailableView for empty states
    - UIApplication.openSettingsURLString for permission flow

key-files:
  created: []
  modified:
    - DuplicatePhotos/Views/ContentView.swift
    - DuplicatePhotos/ViewModels/ScanViewModel.swift

decisions:
  - id: empty-state-pattern
    what: Use ContentUnavailableView for all empty/error states
    why: iOS 17 native pattern, consistent with system apps, better UX
    alternatives: Custom VStack layouts with manual styling
  - id: permission-state-tracking
    what: Add explicit permissionState published property
    why: Clear separation of permission errors from general errors
    alternatives: Use errorMessage for all error types
  - id: settings-deep-link
    what: Open Settings button uses UIApplication.openSettingsURLString
    why: Standard iOS pattern for permission resolution
    alternatives: Show instructions only without direct link
---

# Phase 73 Plan 02: Empty States & Permission UI Summary

**One-liner:** Native ContentUnavailableView for empty states and permission denied/restricted handling with Settings deep link

## What Was Built

Enhanced the app's empty state and permission error UX by replacing custom layouts with iOS 17's native ContentUnavailableView pattern and adding proper permission state tracking.

### Task 1: Replace EmptyScanView with ContentUnavailableView
- Removed custom VStack layout with Spacer, Image, and Text components
- Removed diagnostic info section (was for debugging, not needed for polish)
- Implemented ContentUnavailableView with:
  - Label: "No Duplicates Found" with checkmark.circle icon
  - Description: "Your photo library looks clean! All your photos appear to be unique."
  - Action: "Scan Again" button with .borderedProminent style
- Maintained navigationTitle for consistency
- Result: Native, consistent look that matches system apps

**Commit:** `50ffaa0` - feat(73-02): replace EmptyScanView with ContentUnavailableView

### Task 2: Add Permission Error State Handling
- Added `PermissionState` enum with cases: notDetermined, authorized, limited, denied, restricted
- Added `@Published var permissionState: PermissionState` to ScanViewModel
- Updated `startScan()` to catch PhotoLibraryService.PhotoLibraryError:
  - accessDenied → set permissionState to .denied
  - accessRestricted → set permissionState to .restricted
  - Other errors → show in errorMessage as before
- Created `PermissionDeniedView`:
  - ContentUnavailableView with photo.badge.exclamationmark icon
  - Description: "Please allow access to your photos in Settings to scan for duplicates."
  - "Open Settings" button that opens UIApplication.openSettingsURLString
- Created `PermissionRestrictedView`:
  - ContentUnavailableView with lock.shield icon
  - Description: "Photo library access is restricted by parental controls or device management. Contact your administrator."
  - No action button (user must contact administrator)
- Updated ScanView to conditionally show:
  1. PermissionDeniedView if permissionState == .denied
  2. PermissionRestrictedView if permissionState == .restricted
  3. ScanProgressView if isScanning
  4. DuplicateGroupsListView if duplicateGroups not empty
  5. EmptyScanView otherwise

**Commit:** `6f59063` - feat(73-02): add permission error state handling

## Verification Results

✅ Build succeeded without warnings
✅ EmptyScanView uses ContentUnavailableView (not custom VStack)
✅ PermissionDeniedView exists with "Open Settings" button
✅ PermissionRestrictedView exists with parental controls explanation
✅ ScanView conditionally shows appropriate view based on permission state
✅ ScanViewModel has permissionState property
✅ All views have appropriate navigationTitle

## Deviations from Plan

None - plan executed exactly as written.

## Technical Details

### ContentUnavailableView Pattern
iOS 17 introduced ContentUnavailableView as a standard way to show empty states. The API provides:
- Consistent visual design across system apps
- Automatic spacing and layout
- Support for label, description, and actions
- Dark mode support built-in

### Permission Flow
1. User launches app → ScanView appears
2. .task auto-starts scan → calls viewModel.startScan()
3. startScan() calls detector.scanForDuplicates()
4. detector calls photoLibrary.fetchAllPhotos()
5. photoLibrary.requestAuthorization() throws PhotoLibraryError.accessDenied
6. startScan() catches error, sets permissionState = .denied
7. ScanView re-renders, shows PermissionDeniedView
8. User taps "Open Settings" → iOS Settings app opens to app's permission page
9. User enables permission → returns to app
10. User taps "Start Scan" button on main screen → scan proceeds

### Settings Deep Link
`UIApplication.openSettingsURLString` is a system constant that resolves to:
- "app-settings:" URL scheme on iOS
- Opens Settings app directly to the current app's permissions page
- Standard pattern used by all system and well-designed third-party apps

## Files Modified

### DuplicatePhotos/Views/ContentView.swift
- Added `import UIKit` for UIApplication
- Replaced EmptyScanView implementation with ContentUnavailableView
- Added PermissionDeniedView struct
- Added PermissionRestrictedView struct
- Updated ScanView body to check permissionState first

**Before (EmptyScanView):**
```swift
VStack(spacing: 24) {
    Spacer()
    Image(systemName: "checkmark.circle")
        .font(.system(size: 80))
    // ... custom layout
}
```

**After:**
```swift
ContentUnavailableView {
    Label("No Duplicates Found", systemImage: "checkmark.circle")
} description: {
    Text("Your photo library looks clean! All your photos appear to be unique.")
} actions: {
    Button { /* ... */ } label: { Text("Scan Again") }
        .buttonStyle(.borderedProminent)
}
```

### DuplicatePhotos/ViewModels/ScanViewModel.swift
- Added PermissionState enum at top of file
- Added `@Published var permissionState: PermissionState = .notDetermined`
- Updated startScan() to:
  - Reset permissionState to .notDetermined at start
  - Set permissionState to .authorized on successful scan
  - Catch PhotoLibraryService.PhotoLibraryError specifically
  - Map error types to permissionState values

## Performance Impact

- No performance impact
- ContentUnavailableView is lightweight system component
- Permission state tracking adds negligible memory overhead

## Testing Notes

**Manual testing required:**
1. Deny photo permission in simulator settings
2. Launch app → ScanView auto-starts scan
3. Verify PermissionDeniedView appears
4. Tap "Open Settings" → verify iOS Settings opens
5. Enable permission, return to app
6. Tap "Start Scan" from main screen → verify scan proceeds

**Simulator permission reset:**
```bash
xcrun simctl privacy booted reset photos com.yourcompany.DuplicatePhotos
```

## Next Phase Readiness

**Blockers:** None

**Concerns:** None

**Recommendations:**
- Consider adding VoiceOver labels for accessibility
- Consider adding haptic feedback on permission denial
- Consider showing permission prompt proactively on first launch

## Screenshots/Examples

**Empty state (no duplicates):**
- Checkmark.circle icon (green gradient)
- "No Duplicates Found" title
- "Your photo library looks clean! All your photos appear to be unique." description
- "Scan Again" button (bordered prominent style)

**Permission denied:**
- Photo.badge.exclamationmark icon
- "Photo Access Required" title
- "Please allow access to your photos in Settings to scan for duplicates." description
- "Open Settings" button (bordered prominent style)

**Permission restricted:**
- Lock.shield icon
- "Access Restricted" title
- "Photo library access is restricted by parental controls or device management. Contact your administrator." description
- No action button

## Related Documentation

- Apple HIG: [Empty States](https://developer.apple.com/design/human-interface-guidelines/patterns/empty-states)
- iOS 17: [ContentUnavailableView](https://developer.apple.com/documentation/swiftui/contentunavailableview)
- Photo Library: [PHAuthorizationStatus](https://developer.apple.com/documentation/photokit/phauthorizationstatus)

## Lessons Learned

1. **ContentUnavailableView is powerful:** Single component replaces 40+ lines of custom layout code
2. **Permission states need explicit tracking:** Mixing permission errors with general errors confuses UX
3. **Settings deep link is standard:** Users expect "Open Settings" button for permission issues
4. **Restricted vs Denied matters:** Different error messages for different permission states improves clarity

## Commit History

| Commit  | Type | Description                                             |
| ------- | ---- | ------------------------------------------------------- |
| 50ffaa0 | feat | Replace EmptyScanView with ContentUnavailableView       |
| 6f59063 | feat | Add permission error state handling                     |

## Metrics

- Tasks completed: 2/2
- Files modified: 2
- Lines added: 62
- Lines removed: 45
- Build time: ~30s
- Execution time: 3 minutes
