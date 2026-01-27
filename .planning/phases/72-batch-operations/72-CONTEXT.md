# Phase 72: Batch Operations - Context

**Gathered:** 2026-01-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can delete multiple duplicates with one action. This includes single-group deletion and bulk "delete all duplicates" across all groups. Does not include smart photo selection algorithms or dismissing duplicates without deletion.

</domain>

<decisions>
## Implementation Decisions

### Selection Strategy
- Auto-select best photo to keep by default (app picks)
- User can deselect photos to keep both/all instances of a duplicate
- "Delete all duplicates" button affects all groups at once
- Pre-selection can be overridden before confirming

### Deletion Behavior
- Deletion happens immediately after user action
- Group disappears from list after photos deleted
- Continue processing other groups if some deletions fail, report failures at end
- Restored photos from Recently Deleted will appear in next scan if still similar

### Confirmation Flow
- Single-group deletion: No confirmation (iOS Recently Deleted is safety net)
- Bulk "delete all": Alert dialog with photo count ("Delete 47 photos?")
- Delete button uses standard iOS destructive red styling
- No special first-time warning

### Feedback & Recovery
- Brief toast/banner after deletion ("Deleted 3 photos")
- Rely on iOS Recently Deleted for recovery (no in-app undo)
- No tracking of dismissed pairs — clean slate each scan

### Claude's Discretion
- Criteria for determining "best" photo to keep (resolution, file size, recency heuristics)
- Implementation of bulk delete (single transaction vs group-by-group with progress)
- Toast styling and duration

</decisions>

<specifics>
## Specific Ideas

- User wants to be able to deselect to keep both instances — not forced into deleting
- Bulk select all is important for efficiency
- Keep it simple: no confirmation on single deletes, trust iOS safety net

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 72-batch-operations*
*Context gathered: 2026-01-27*
