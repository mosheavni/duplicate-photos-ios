---
created: 2026-01-27T14:30
title: App crashes when deleting a duplicate
area: ui
files:
  - DuplicatePhotos/Views/GroupDetailView.swift
---

## Problem

When user attempts to delete a duplicate photo from the results, the app crashes. This is a critical bug that prevents the core user workflow (identifying and removing duplicates).

Likely involves:
- PHPhotoLibrary.shared().performChanges async handling
- State management after deletion (duplicateGroups array mutation)
- Potential force unwrap or index out of bounds

## Solution

TBD - needs investigation:
1. Add crash logging / breakpoint to identify exact crash point
2. Check PHPhotoLibrary deletion error handling
3. Verify state updates after successful deletion
4. Test with async/await proper error propagation
