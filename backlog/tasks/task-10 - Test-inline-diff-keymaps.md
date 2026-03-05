---
id: TASK-10
title: 'Test inline diff keymaps (=, >, <)'
status: To Do
assignee: []
created_date: '2026-03-05 16:43'
labels:
  - test
  - status-buffer
  - keymap
milestone: m-0
dependencies: []
references:
  - 'autoload/fujjitive.vim:4934'
  - 'autoload/fujjitive.vim:4911'
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add test coverage for inline diff toggle/show/hide keymaps in the status buffer.

**Handler:** `s:StageInline(mode, lnum, count)` (line 4934). `=` toggles, `>` shows, `<` hides inline diffs for the file under the cursor.

**Mechanism:** Direct buffer manipulation (no feedkeys). Shows diff by extracting from `b:fujjitive_status.diff[section]` (pre-fetched async), appends diff lines after the file entry. Hides by deleting those lines. Tracks state in `b:fujjitive_expanded[section][filename]`.

**Test approach:** This requires `b:fujjitive_status.diff` to be populated, which happens during status buffer creation. The simplest approach is to open a real status buffer (`:J`) with actual changes in the repo, then call `SFunc('StageInline')` and check buffer line count / content changes.

**Helper function:** `s:StageInlineGetDiff()` (line 4911) fetches diff from cached async results.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test `=` on a file line with changes expands inline diff lines below the file entry
- [ ] #2 Test `=` again on the same file line collapses the inline diff
- [ ] #3 Test `>` forces expansion of inline diff
- [ ] #4 Test `<` forces collapse of inline diff
- [ ] #5 Expanded diff lines contain diff content (e.g. `+` and `-` lines or `@@` headers)
- [ ] #6 Test file in test/ named test_inline_diff.sh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All new tests pass locally via `bash test/run_tests.sh`
- [ ] #2 Existing tests still pass (no regressions)
- [ ] #3 vint lint passes: `vint -e plugin/ autoload/ ftplugin/ ftdetect/ syntax/`
- [ ] #4 Tests follow established patterns from helpers.sh (setup_jj_repo / run_nvim_test_in / pass / fail / cleanup / finish)
<!-- DOD:END -->
