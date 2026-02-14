---
id: TASK-6
title: >-
  Add workspace indicators to status buffer and preserve workspace working
  copies from empty filter
status: In Progress
assignee: []
created_date: '2026-02-14 12:54'
updated_date: '2026-02-14 12:58'
labels: []
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Empty revisions attached to workspaces should not be filtered out of the "Other mutable" section in the status buffer. Additionally, workspace indicators (e.g., `default@`) should be displayed alongside revisions so users can see which workspaces are associated with each revision.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Workspace working copies are never filtered out of the 'Other mutable' section, even when empty with no description
- [ ] #2 s:QueryLog() template includes working_copies data from jj
- [ ] #3 s:FormatLog() displays workspace indicators (e.g., 'default@') in log lines
- [ ] #4 Syntax highlighting is added for workspace indicators in the status buffer
- [ ] #5 Existing empty-revision filtering still works for non-workspace revisions
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### Step 1: Extend `s:QueryLog()` template (autoload/fujjitive.vim ~line 2697)
Add `working_copies` to the jj log template as a new tab-separated column. Use `working_copies` which renders as `name@` for workspace revisions and empty string otherwise.

### Step 2: Parse workspace data in `s:QueryLog()` (autoload/fujjitive.vim ~line 2708)
Add a `working_copies` key to the parsed dictionary from the new template column.

### Step 3: Fix the empty-revision filter (autoload/fujjitive.vim line 3041)
Update the filter to preserve entries that have workspace assignments:
```vim
call filter(stat.other_mutable_log.entries,
  \ '!(v:val.empty && empty(v:val.subject) && empty(v:val.working_copies))')
```

### Step 4: Display workspace indicators in `s:FormatLog()` (autoload/fujjitive.vim ~line 2604)
Show workspace indicator after the change ID (similar position to bookmarks), e.g.:
```
v default@ (empty) (no description set)
```

### Step 5: Add syntax highlighting (syntax/fujjitive.vim)
Add a syntax match for workspace indicators (`\w\+@` pattern) and link to an appropriate highlight group.
<!-- SECTION:PLAN:END -->
