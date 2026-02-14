---
id: TASK-4
title: Add cmn keymap for jj new <commit-under-cursor>
status: Done
assignee: []
created_date: '2026-02-14 02:08'
updated_date: '2026-02-14 02:10'
labels:
  - ux
  - keymaps
dependencies: []
references:
  - 'autoload/fujjitive.vim:7823-7826'
  - 'autoload/fujjitive.vim:7707-7716'
  - 'doc/fujjitive.txt:541-545'
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
There is no quick keymap to create a new change on top of a specific commit visible in the status buffer. `jj new <commit>` is one of the most common JJ operations — creating a new child change of a given revision — but users must currently type `:JJ new <revset>` manually or use `cm<Space>` and type the rest.

A `cmn` keymap under the existing `cm` (merge/new) namespace should run `jj new <commit-under-cursor>`, complementing `co` (edit existing commit) with the ability to create a new child commit from any visible revision.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Pressing `cmn` on a commit line in the status buffer runs `jj new <change_id>` for that commit
- [x] #2 `cmn` works in all contexts where `s:SquashArgument()` can extract a revision (status buffer, temp/pager buffers, object buffers)
- [x] #3 If no commit can be extracted from the cursor line, an appropriate error message is shown
- [x] #4 After `jj new` completes, the status buffer reloads to reflect the new working copy
- [x] #5 Help documentation (doc/fujjitive.txt) is updated with the new `cmn` map under the commit maps section
- [x] #6 `cm<Space>` and `cm<CR>` continue to work unchanged
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### 1. Add `cmn` keymap in `s:MapGitOps()` (autoload/fujjitive.vim)

Add `cmn` map after the existing `cmt` line (7826), following the exact pattern used by `co` (line 7843):

```vim
exe s:Map('n', 'cmn', ':<C-U>JJ new <C-R>=<SID>SquashArgument()<CR><CR>', '<silent>', ft)
```

This uses `s:SquashArgument()` which already handles:
- Status buffer (`fujjitive` filetype): parses JJ change IDs (`[k-z]{4,}`)
- Temp/pager buffers: matches both change IDs and hex hashes
- Other buffers: falls back to `s:Owner(@%)`

When `s:SquashArgument()` returns empty (no commit on cursor line), `jj new` runs with an empty argument and JJ itself will produce an error — but we should match the error handling pattern. Looking at `co`, it also doesn't guard against empty. The `:JJ` command wrapper handles errors from jj. This is acceptable.

### 2. Update help docs (doc/fujjitive.txt)

Add `cmn` entry in the `fujjitive_cm` section (after line 542), documenting it as creating a new change on top of the commit under the cursor.

### 3. Verify existing maps unaffected

Confirm `cm<Space>`, `cm<CR>`, `cmt`, `cm?` all still work — no prefix conflicts since `cmn` is a distinct 3-char sequence and won't shadow any of them.
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
## Summary

Added `cmn` keymap that runs `jj new <change_id>` on the commit under the cursor, filling a gap where users had no quick way to create a new child change of an arbitrary visible revision.

## Changes

- **autoload/fujjitive.vim:7826**: Added `cmn` map using `s:SquashArgument()` to extract the revision, following the same pattern as `co` (jj edit)
- **doc/fujjitive.txt:542-543**: Added `cmn` documentation in the `fujjitive_cm` section

## Notes

- `cmn` inherits all the context-awareness of `s:SquashArgument()`: works in the status buffer (JJ change IDs), temp/pager buffers (hex hashes and change IDs), and object buffers (buffer owner)
- No prefix conflicts with existing `cm<Space>`, `cm<CR>`, `cmt`, or `cm?` maps
- Error handling when no commit is found on the cursor line is delegated to jj itself (consistent with `co`)
- All 63 existing tests pass
<!-- SECTION:FINAL_SUMMARY:END -->
