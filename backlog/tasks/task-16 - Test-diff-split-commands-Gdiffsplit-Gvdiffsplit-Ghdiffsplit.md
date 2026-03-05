---
id: TASK-16
title: 'Test diff split commands (:Gdiffsplit, :Gvdiffsplit, :Ghdiffsplit)'
status: To Do
assignee: []
created_date: '2026-03-05 16:44'
labels:
  - test
  - ex-command
milestone: m-2
dependencies: []
references:
  - 'autoload/fujjitive.vim:6604'
  - 'autoload/fujjitive.vim:5000'
  - 'plugin/fujjitive.vim:601'
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add test coverage for the vimdiff integration commands that open split windows comparing file versions.

**Handler:** `fujjitive#Diffsplit(autodir, keepfocus, mods, arg)` (line 6604). Opens a split with diff view comparing the current file against a revision (defaults to `@-:` for parent).

**Also mapped in status buffer** as `dd`, `dh`/`ds`, `dv` via `s:StageDiff()` (line 5000), which opens the file then runs the diff split.

**Test approach:**
- Open a tracked file in a jj repo, run `:Gdiffsplit`, verify two windows exist with `&diff` set.
- Test `:Gvdiffsplit` creates a vertical split.
- Test `:Ghdiffsplit` creates a horizontal split.
- Test `dd`/`dv`/`dh` from status buffer file lines.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test `:Gdiffsplit` opens two windows with `&diff` enabled
- [ ] #2 Test `:Gvdiffsplit` creates a vertical diff split
- [ ] #3 Test `:Ghdiffsplit` creates a horizontal diff split
- [ ] #4 Test `dd` from status buffer file line opens a diff split for that file
- [ ] #5 Test the parent revision (@-) is used as the default comparison target
- [ ] #6 Test file in test/ named test_diffsplit.sh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All new tests pass locally via `bash test/run_tests.sh`
- [ ] #2 Existing tests still pass (no regressions)
- [ ] #3 vint lint passes: `vint -e plugin/ autoload/ ftplugin/ ftdetect/ syntax/`
- [ ] #4 Tests follow established patterns from helpers.sh (setup_jj_repo / run_nvim_test_in / pass / fail / cleanup / finish)
<!-- DOD:END -->
