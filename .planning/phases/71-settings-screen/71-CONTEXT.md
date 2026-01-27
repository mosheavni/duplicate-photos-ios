# Phase 71: Settings Screen - Context

**Gathered:** 2026-01-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Let users adjust similarity threshold from the UI. Settings screen accessible from main view with threshold slider, cache management, and about info.

</domain>

<decisions>
## Implementation Decisions

### Settings Placement
- Gear icon in top-right nav bar on main/home screen only
- Not visible on other screens in navigation stack
- Navigation style: Claude's discretion (push vs modal)
- Access during/after scan: Claude's discretion

### Threshold Control
- Slider control (not presets or picker)
- Show percentage above/next to slider (e.g., "92%")
- Range: Claude's discretion (suggested 85-99%)
- Changes apply immediately (auto-save, standard iOS behavior)

### Settings Scope
Include these sections:
1. **Similarity Threshold** - slider with percentage
2. **Cache Management** - clear button + stats (cached photo count)
3. **About** - version, credits (static, no external links)
4. **Reset to Defaults** - button to restore threshold to 92%

### Feedback & Guidance
- Threshold slider has explanatory text: "Higher = stricter matching, fewer results"
- Clear Cache shows confirmation alert before action
- After clearing: show success message/toast
- About section: static info only, no links

### Claude's Discretion
- Navigation presentation style (push vs sheet)
- Whether settings accessible from results screen
- Exact slider range bounds
- Visual styling and spacing
- Toast/alert implementation details

</decisions>

<specifics>
## Specific Ideas

- Follow standard iOS Settings patterns
- Keep it simple - this is MVP
- Cache stats help with debugging (leftover from Phase 70 troubleshooting)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 71-settings-screen*
*Context gathered: 2026-01-27*
