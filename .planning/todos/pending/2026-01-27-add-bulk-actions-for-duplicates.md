---
created: 2026-01-27T14:40
title: Add bulk actions for duplicates (merge, delete)
area: ui
files:
  - DuplicatePhotos/Views/GroupDetailView.swift
  - DuplicatePhotos/Views/ResultsView.swift
---

## Problem

Currently user must handle duplicates one at a time. For a large photo library with many duplicates, this is tedious and time-consuming.

User wants bulk operations:
- Bulk merge: Keep best from each group, delete rest
- Bulk delete: Delete selected duplicates across multiple groups
- "Delete all but first" across all groups at once

Note: Phase 72 in ROADMAP.md already plans "Batch Operations" with "Delete all but first" button. This todo captures the broader bulk actions feature request beyond single-group batch delete.

## Solution

TBD - consider:
1. Multi-select mode in results list
2. "Select All" / "Deselect All" controls
3. Bulk action toolbar (Delete Selected, Keep Selected)
4. Smart "Auto-resolve" that keeps highest quality from each group
5. Confirmation showing total count before bulk action
