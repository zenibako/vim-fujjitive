---
id: TASK-17
title: 'Test file operation commands (:GMove, :GRename, :GDelete, :GRemove)'
status: To Do
assignee: []
created_date: '2026-03-05 16:45'
labels:
  - test
  - ex-command
milestone: m-2
dependencies: []
references:
  - 'autoload/fujjitive.vim:6749'
  - 'autoload/fujjitive.vim:6822'
  - 'plugin/fujjitive.vim:609'
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add test coverage for file operation wrapper commands.

**Handlers:**
- `:GMove` → `s:Move(bang, 0, arg)` (line 6749): Runs `jj mv` to move a file, updates buffer via `saveas!`.
- `:GRename` → `s:Move(bang, 1, arg)` (line 6749): Same as Move but `rename=1` means relative path handling.
- `:GRemove` → `s:Remove('edit', bang)` (line 6822): Runs `jj file untrack`, keeps buffer open.
- `:GDelete` → `s:Remove('bdelete', bang)` (line 6822): Runs `jj file untrack`, deletes buffer.

**Test approach:** Open a tracked file, run the commands, verify file system state and buffer state change correctly.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test `:GMove newpath` moves the file and updates the buffer filename
- [ ] #2 Test `:GRename newname` renames the file within the same directory
- [ ] #3 Test `:GRemove` untracks the file but keeps the buffer
- [ ] #4 Test `:GDelete` untracks the file and deletes the buffer
- [ ] #5 Test file in test/ named test_file_operations.sh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All new tests pass locally via `bash test/run_tests.sh`
- [ ] #2 Existing tests still pass (no regressions)
- [ ] #3 vint lint passes: `vint -e plugin/ autoload/ ftplugin/ ftdetect/ syntax/`
- [ ] #4 Tests follow established patterns from helpers.sh (setup_jj_repo / run_nvim_test_in / pass / fail / cleanup / finish)
<!-- DOD:END -->
