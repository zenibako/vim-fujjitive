---
id: TASK-14
title: Test edit/checkout (co) and bookmark set (cB) keymaps
status: To Do
assignee: []
created_date: '2026-03-05 16:44'
labels:
  - test
  - status-buffer
  - keymap
milestone: m-1
dependencies: []
references:
  - 'autoload/fujjitive.vim:7985'
  - 'autoload/fujjitive.vim:7851'
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add test coverage for the `co` (edit commit under cursor) and `cB` (set bookmark to working copy) keymaps.

**Handlers:**
- `co` (line 7985): `execute s:SquashCommand("JJ edit")` — runs `:JJ edit <revision>` where revision comes from `s:SquashArgument()`.
- `cB` (line 7991): `execute s:BookmarkSetWC()` — calls `s:BookmarkSetWC()` (lines 7851-7871) which checks the cursor is on a bookmark line, determines the bookmark name, and returns `:JJ bookmark set <name> -r @` (or `-r @-` if working copy is empty).

**Test approach:** Inject status buffer content with commit/bookmark lines. For `co`, verify the correct `:JJ edit <change_id>` command is constructed. For `cB`, verify `:JJ bookmark set <name> -r @` is constructed.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test `co` on a commit line constructs `:JJ edit <change_id>`
- [ ] #2 Test `cB` on a bookmark line constructs `:JJ bookmark set <name> -r @`
- [ ] #3 Test `cB` returns an error when cursor is not on a bookmark line
- [ ] #4 Test file in test/ named test_edit_bookmark.sh or added to test_commit_maps.sh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All new tests pass locally via `bash test/run_tests.sh`
- [ ] #2 Existing tests still pass (no regressions)
- [ ] #3 vint lint passes: `vint -e plugin/ autoload/ ftplugin/ ftdetect/ syntax/`
- [ ] #4 Tests follow established patterns from helpers.sh (setup_jj_repo / run_nvim_test_in / pass / fail / cleanup / finish)
<!-- DOD:END -->
