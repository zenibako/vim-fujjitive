---
id: TASK-18
title: 'Test read/write commands (:Gread, :Gwrite, :Gwq)'
status: To Do
assignee: []
created_date: '2026-03-05 16:45'
labels:
  - test
  - ex-command
milestone: m-2
dependencies: []
references:
  - 'autoload/fujjitive.vim:6320'
  - 'autoload/fujjitive.vim:6348'
  - 'autoload/fujjitive.vim:6479'
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add test coverage for the read/write file commands.

**Handlers:**
- `:Gread` → `fujjitive#ReadCommand()` (line 6320): Reads file contents from a specified revision into the current buffer.
- `:Gwrite` → `fujjitive#WriteCommand()` (line 6348): Writes buffer contents and adds/tracks the file via `jj add`.
- `:Gwq` → `fujjitive#WqCommand()` (line 6479): Delegates to WriteCommand then quits.

**Test approach:** Create a file with changes, use `:Gread` to restore content from a revision, verify buffer contents. Use `:Gwrite` to save and verify file is tracked.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test `:Gread` replaces buffer contents with file content from parent revision
- [ ] #2 Test `:Gwrite` saves the buffer and the file is tracked by jj
- [ ] #3 Test file in test/ named test_read_write.sh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All new tests pass locally via `bash test/run_tests.sh`
- [ ] #2 Existing tests still pass (no regressions)
- [ ] #3 vint lint passes: `vint -e plugin/ autoload/ ftplugin/ ftdetect/ syntax/`
- [ ] #4 Tests follow established patterns from helpers.sh (setup_jj_repo / run_nvim_test_in / pass / fail / cleanup / finish)
<!-- DOD:END -->
