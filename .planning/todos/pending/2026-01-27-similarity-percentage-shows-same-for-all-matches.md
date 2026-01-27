---
created: 2026-01-27T14:35
title: Similarity percentage shows same value for all matches
area: ui
files:
  - DuplicatePhotos/Views/GroupDetailView.swift
  - DuplicatePhotos/Services/SimilarityService.swift
  - DuplicatePhotos/Models/DuplicateGroup.swift
---

## Problem

After scanning, all duplicate matches display the same similarity percentage in the UI, even though:
- Some duplicates are literally identical (should show 100%)
- Some are only near-duplicates (user estimates ~85%)

This suggests either:
1. The actual similarity scores aren't being stored/passed to the UI
2. A hardcoded or default value is being displayed
3. The grouping algorithm loses per-pair similarity data
4. UI is showing group-level threshold instead of pair-level scores

## Solution

TBD - needs investigation:
1. Check if DuplicateGroup model stores per-photo similarity scores
2. Verify SimilarityService returns actual scores (not just pass/fail)
3. Check how GroupDetailView gets/displays the percentage
4. May need to store similarity matrix or per-pair scores in the group model
