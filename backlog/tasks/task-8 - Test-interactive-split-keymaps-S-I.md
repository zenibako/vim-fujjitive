---
id: TASK-8
title: 'Test interactive split keymaps (S, I)'
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
  - 'autoload/fujjitive.vim:5363'
  - test/test_terminal_routing.sh
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add test coverage for the interactive split keymaps `S` and `I` in the status buffer. These open `jj split --interactive` in a terminal tab.

**Handler:** `s:StagePatch()` (line 5363). On section heading: runs `tab JJ split --interactive`. On file lines: runs `tab JJ split --interactive -- <paths>`. On Unpushed section: delegates to `s:DoStageUnpushed` (uses feedkeys for push).

**Mechanism:** Uses direct ex commands (`:tab JJ split --interactive`). Since interactive jj requires a terminal, test the command construction rather than full execution. Use `maparg()` verification and/or SFunc call patterns similar to test_terminal_routing.sh.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test `S` on Unstaged heading triggers `split --interactive` command
- [ ] #2 Test `S` on a file line includes `-- <filename>` in the split command
- [ ] #3 Test `I` variant also triggers interactive split
- [ ] #4 Test file in test/ named appropriately or added to test_split_squash.sh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All new tests pass locally via `bash test/run_tests.sh`
- [ ] #2 Existing tests still pass (no regressions)
- [ ] #3 vint lint passes: `vint -e plugin/ autoload/ ftplugin/ ftdetect/ syntax/`
- [ ] #4 Tests follow established patterns from helpers.sh (setup_jj_repo / run_nvim_test_in / pass / fail / cleanup / finish)
<!-- DOD:END -->
