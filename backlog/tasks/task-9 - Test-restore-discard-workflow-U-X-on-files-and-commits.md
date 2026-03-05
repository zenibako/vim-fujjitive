---
id: TASK-9
title: 'Test restore/discard workflow (U, X on files and commits)'
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
  - 'autoload/fujjitive.vim:5092'
  - 'autoload/fujjitive.vim:5144'
  - test/test_bookmark_delete.sh
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add test coverage for the restore and discard keymaps. Bookmark `X` is already tested in test_bookmark_delete.sh, but `X` on files and commits plus `U` (restore all) have zero coverage.

**Handlers:**
- `U` (line 2808): Direct `:JJ restore` ex command. Restores all working copy changes.
- `X` on files via `s:StageDelete()` (line 5144-5181): For untracked files (`?` status), calls `delete()`. For tracked files, calls `s:TreeChomp(['restore', '--from', '@-', '--'] + paths)`. No feedkeys — direct side effects.
- `X` on commits via `s:StageDelete()` (line 5105-5112): Uses `feedkeys(':JJ abandon ' + commit_ids)`. Testable via DrainTypeahead.
- `X` on section headings (line 5096-5104): Uses `feedkeys(':JJ abandon "<revset>"')` with `abandon_revsets` dict.

**Test approach:**
- `U`: Create changes, execute `:JJ restore`, verify `jj diff` is empty.
- `X` on files: Inject file lines in status buffer, call `SFunc('StageDelete')`, verify file is restored or deleted.
- `X` on commits: Inject commit lines, call `SFunc('StageDelete')`, drain typeahead for `:JJ abandon`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test `U` restores all working copy changes (jj diff empty after)
- [ ] #2 Test `X` on a tracked file in Unstaged section restores it from parent (@-)
- [ ] #3 Test `X` on an untracked file deletes it from the filesystem
- [ ] #4 Test `X` on a commit line populates typeahead with `:JJ abandon <change_id>`
- [ ] #5 Test `X` on a section heading (e.g. Current) populates typeahead with `:JJ abandon` and the correct revset
- [ ] #6 Test visual-mode `X` on multiple commit lines includes all change IDs
- [ ] #7 Test file in test/ named test_restore_discard.sh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All new tests pass locally via `bash test/run_tests.sh`
- [ ] #2 Existing tests still pass (no regressions)
- [ ] #3 vint lint passes: `vint -e plugin/ autoload/ ftplugin/ ftdetect/ syntax/`
- [ ] #4 Tests follow established patterns from helpers.sh (setup_jj_repo / run_nvim_test_in / pass / fail / cleanup / finish)
<!-- DOD:END -->
