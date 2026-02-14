---
id: TASK-6
title: Fix jj show / commit object viewing from status buffer
status: Done
assignee: []
created_date: '2026-02-14 12:53'
updated_date: '2026-02-14 13:01'
labels:
  - bug
  - jj-compat
dependencies: []
references:
  - 'autoload/fujjitive.vim:3163'
  - 'autoload/fujjitive.vim:4496'
  - 'autoload/fujjitive.vim:2604'
  - test/test_jj_show.sh
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Three interrelated bugs prevent viewing commit objects in vim-fujjitive when using jj (not git):

1. **BufReadCmd uses `cat-file -t`** (line 3163) to determine object type, but jj doesn't have `cat-file`. This makes `:Gedit <hash>` produce an empty buffer.

2. **`s:FormatLog` doesn't include commit_id** — the formatted log line only shows the change_id (e.g. `xv·unvwnm`), so `s:StageInfo` regex `[0-9a-f]{4,}` can't extract a hex commit hash from Ancestors lines.

3. **`<CR>` on commit lines does nothing** — consequence of bug 2. `info.commit` is always empty, so `s:CfilePorcelain` returns `['']`.

These bugs were discovered and confirmed by test/test_jj_show.sh (3 failing tests).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 `:Gedit <commit-hash>` opens a buffer with commit metadata (author, description) instead of an empty buffer
- [x] #2 `<CR>` on a commit line in the Ancestors section of the status buffer navigates to the commit object
- [x] #3 s:StageInfo extracts a usable commit identifier from jj-formatted log lines in the status buffer
- [x] #4 All 9 tests in test/test_jj_show.sh pass
- [x] #5 All pre-existing tests continue to pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### Fix 1: Add commit_id to FormatLog (Bug 2 — StageInfo + CR navigation)

**File:** `autoload/fujjitive.vim`, `s:FormatLog()` (line 2604)

Add the `commit_id` field to the formatted log line, right after the change_id. Current format:
```
change_id·rest [bookmarks] [(empty)] [(conflict)] subject
```
New format:
```
change_id·rest commit_id [bookmarks] [(empty)] [(conflict)] subject
```

The `commit_id` is an 8-char hex string (e.g. `aeba9399`) already available in the dict from `s:QueryLog`. The existing `s:StageInfo` regex `[0-9a-f]{4,}` will match it naturally. This fixes both the StageInfo extraction (Bug 2) and `<CR>` navigation (Bug 3).

### Fix 2: Replace `cat-file -t` in BufReadCmd (Bug 1 — Gedit)

**File:** `autoload/fujjitive.vim`, `fujjitive#BufReadCmd()` (line 3163)

Replace `cat-file -t` (git-only) with `jj log -r <rev> -T 'commit_id'`. If it succeeds, the rev is valid — set `b:fujjitive_type = 'commit'` (jj doesn't have tree/blob/tag at the revision level). If it fails, fall through to the existing error handling.

### Fix 3: Replace `rev-parse --verify` in fujjitive#Find (Bug 1 — Gedit)

**File:** `autoload/fujjitive.vim`, `fujjitive#Find()` (line 1927)

Replace `rev-parse --verify <commit>` with `jj log --no-graph -r <commit> -T 'commit_id'` to resolve short commit hashes to full 40-char hashes. This is needed because after `cat-file -t` is fixed, the URL construction still depends on resolving the hash.

### Verification

- All 9 tests in `test/test_jj_show.sh` pass
- All pre-existing tests continue to pass
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
## Summary

Fixed three interrelated bugs that prevented viewing commit objects in vim-fujjitive when using jj.

### Changes

**`autoload/fujjitive.vim`:**
- `s:FormatLog()` (line ~2610): Added `commit_id` field to formatted log lines, so the line format is now `change_id·rest commit_id [bookmarks] subject`. This gives `s:StageInfo` a hex hash to extract.
- `s:StageInfo()` (line ~4504): Updated the commit regex from `\l\+\s\+` to `\l\+\%(\%u00b7\l*\)\=\s\+` to handle the middle-dot separator (U+00B7) in jj change IDs.
- `fujjitive#BufReadCmd()` (line ~3169): Replaced `cat-file -t` with `jj log --no-graph -r <rev> -T 'commit_id'` for object type detection. All jj revisions are commits.
- `fujjitive#Find()` (line ~1927): Replaced `rev-parse --verify` with `jj log --no-graph -r <rev> -T 'commit_id'` for resolving short hashes to full 40-char commit IDs.

**`test/test_jj_show.sh`:**
- Updated the StageInfo regex test to match the new pattern with `\%u00b7`.

### Test Results

All 12 test scripts pass (71 total tests), including all 9 jj show tests.
<!-- SECTION:FINAL_SUMMARY:END -->
