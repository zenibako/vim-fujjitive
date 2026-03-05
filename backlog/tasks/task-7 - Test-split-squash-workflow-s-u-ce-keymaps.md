---
id: TASK-7
title: 'Test split/squash workflow (s, u, -, ce keymaps)'
status: In Progress
assignee:
  - claude
created_date: '2026-03-05 16:43'
updated_date: '2026-03-05 19:30'
labels:
  - test
  - status-buffer
  - keymap
milestone: m-0
dependencies: []
references:
  - 'autoload/fujjitive.vim:4661'
  - 'autoload/fujjitive.vim:5310'
  - test/test_summary_mappings.sh
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add test coverage for the split and squash keymaps in the status buffer. These are core jj operations (`jj split` and `jj squash`) mapped to `s`, `u`, `-`, and `ce`. Currently zero test coverage despite being the bread-and-butter jj workflow.

**Handler functions:** `s:Do('Split', 0)`, `s:Do('Squash', 0)`, `s:Do('Toggle', 0)` dispatched through `s:Do()` (line 4661) which calls `s:Do{action}{section}(record)`. The `ce` map runs `:JJ squash` directly.

**Mechanism:** These use `s:TreeChomp()` for direct shell execution (no feedkeys), then `s:ReloadStatus()`. Test by setting up a repo with working copy changes, executing the keymap, and verifying the jj state changed.

**Key functions:** `s:DoSplitUnstaged` (line 5327), `s:DoSplitUnstagedHeading` (line 5322), `s:DoSquashUnstaged` (line 5348), `s:DoSquashUnstagedHeading` (line 5343), `s:DoToggleUnstaged` (line 5310).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test `s` on a file line in Unstaged section runs `jj split -- <file>` and the file moves out of working copy changes
- [ ] #2 Test `s` on Unstaged section heading runs `jj split` (all files)
- [ ] #3 Test `u` on a file line runs `jj squash -- <file>` and the change is absorbed into parent
- [ ] #4 Test `u` on Unstaged section heading runs `jj squash` (all files)
- [ ] #5 Test `-` (toggle) on Unstaged files behaves same as split
- [ ] #6 Test `ce` runs `jj squash` from the status buffer
- [ ] #7 Test file in test/ named test_split_squash.sh
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified auto_commit disabled - backlog operations no longer produce git errors.
<!-- SECTION:NOTES:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All new tests pass locally via `bash test/run_tests.sh`
- [ ] #2 Existing tests still pass (no regressions)
- [ ] #3 vint lint passes: `vint -e plugin/ autoload/ ftplugin/ ftdetect/ syntax/`
- [ ] #4 Tests follow established patterns from helpers.sh (setup_jj_repo / run_nvim_test_in / pass / fail / cleanup / finish)
<!-- DOD:END -->
