---
id: TASK-3
title: >-
  Fix s:SquashArgument() for JJ change IDs and simplify jj edit keymap from coo
  to co
status: Done
assignee: []
created_date: '2026-02-14 01:43'
updated_date: '2026-02-14 01:53'
labels:
  - bug
  - ux
  - keymaps
dependencies: []
references:
  - 'autoload/fujjitive.vim:7707-7716'
  - 'autoload/fujjitive.vim:7840-7843'
  - 'autoload/fujjitive.vim:2591-2608'
  - 'autoload/fujjitive.vim:2678-2695'
  - 'doc/fujjitive.txt:549-559'
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Two related issues affecting revision-targeting keymaps in the status buffer:

**Bug: s:SquashArgument() cannot parse JJ change IDs**

`s:SquashArgument()` (autoload/fujjitive.vim:7707) uses a regex that only matches hex hashes (`[0-9a-f]{4,}`). JJ change IDs are lowercase letters (e.g., `toxmsyym`), not hex. The formatted log lines in the status buffer only display the change_id — the hex commit_id is stored in data but not rendered. This means the regex never matches, `s:SquashArgument()` returns empty string, and all revision-targeting keymaps fail with:

```
error: the following required arguments were not provided:
  <REVSET|-r <REVSET>>
```

Affected keymaps: `coo`, `rm`, `cW`, `rw`, `crc`, `crn`, `ri`, `rf`, `rd`, `rk`, `rx`.

The regex `^\%(\%(\x\x\x\)\@!\l\+\s\+\)\=\zs[0-9a-f]\{4,\}\ze ` was designed for Git commit hashes. It needs to also match JJ change IDs (sequences of 4+ lowercase letters at the start of a line).

**UX improvement: Simplify coo to co**

The `jj edit` keymap requires a 3-key sequence `coo` because the `co` prefix was inherited from fugitive's multi-operation checkout namespace. In JJ, `jj edit` is the only checkout-like operation, so `co` should directly trigger edit.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 s:SquashArgument() correctly extracts JJ change IDs (lowercase letter sequences like `toxmsyym`) from status buffer log lines
- [x] #2 All revision-targeting keymaps work on JJ log lines: coo/co, rm, cW, rw, crc, crn, ri, rf, rd, rk, rx
- [x] #3 s:SquashArgument() continues to work for hex commit hashes in temp/pager buffers
- [x] #4 Pressing `co` on a commit line in the status buffer runs `jj edit <change_id>`
- [x] #5 `coo` is deprecated with an error message pointing users to `co`
- [x] #6 `co<Space>` still populates the command line with `:JJ edit `
- [x] #7 `co?` still shows help
- [x] #8 Help documentation (doc/fujjitive.txt) is updated to reflect the changes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### Part 1: Fix s:SquashArgument() regex for JJ change IDs

**fujjitive filetype branch (line 7709):**
Replace regex with one that matches JJ change IDs (lowercase letter sequences) in addition to hex hashes:
```vim
'^\l\{4,\}\ze \|^\l\+\s\+\zs\l\{4,\}\ze \|^' . s:ref_header . ': \zs\S\+'
```
Three alternatives: change_id at line start (log lines), change_id after prefix word (bookmark lines), ref header.

**temp file branch (line 7711):**
Extend hex-only regex to also match JJ change IDs:
```vim
let commit = matchstr(getline('.'), '\S\@<!\%(\l\{4,\}\|\x\{4,\}\)\S\@!')
```

### Part 2: Simplify coo to co

- Change `coo` map to `co` (same RHS)
- Add `coo` as deprecated with error message
- Keep `co<Space>`, `co<CR>`, `co?` unchanged

### Part 3: Update documentation

Update fujjitive_co section in doc/fujjitive.txt.
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
## Summary\n\nFixed a bug where all revision-targeting keymaps in the status buffer failed because `s:SquashArgument()` only matched hex hashes (`[0-9a-f]`), not JJ change IDs which use the `[k-z]` alphabet. Also simplified the `jj edit` keymap from `coo` (3 keys) to `co` (2 keys).\n\n## Changes\n\n- **autoload/fujjitive.vim:7710**: Replaced hex-only regex with `[k-z]` pattern that matches JJ change IDs in both log lines (change_id at start) and bookmark lines (change_id after bookmark name prefix)\n- **autoload/fujjitive.vim:7712**: Extended temp/pager buffer regex to match both `[k-z]` change IDs and hex commit hashes\n- **autoload/fujjitive.vim:7843-7844**: Changed `coo` to `co` for `jj edit`, added `coo` deprecation message\n- **doc/fujjitive.txt:552-554**: Updated docs to reflect `co` as the canonical keymap with `coo` deprecated\n\n## Testing\n\n- All 63 existing tests pass\n- Regex tested against 13 line format scenarios (log lines, bookmark lines with various name formats, file lines, section headings, headers, empty lines) — all pass
<!-- SECTION:FINAL_SUMMARY:END -->
