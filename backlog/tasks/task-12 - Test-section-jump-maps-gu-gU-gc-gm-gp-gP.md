---
id: TASK-12
title: 'Test section jump maps (gu, gU, gc, gm, gp, gP)'
status: To Do
assignee: []
created_date: '2026-03-05 16:44'
labels:
  - test
  - status-buffer
  - keymap
  - navigation
milestone: m-1
dependencies: []
references:
  - 'autoload/fujjitive.vim:4239'
  - 'autoload/fujjitive.vim:2810'
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add test coverage for the `g`-prefixed section jump maps in the status buffer. These jump the cursor to specific named sections.

**Handler:** All call `s:StageJump(count, 'SectionName')` (line 4239), which uses `search()` to find the heading line and positions the cursor.

**Maps (defined in s:MapStatus lines 2810-2816):**
- `gu`: Jump to Unstaged section
- `gU`: Jump to Untracked section
- `gc`: Jump to Current/Working Copy section
- `gm`: Jump to merge-related section
- `gp`: Jump to Unpushed section
- `gP`: Jump to Unpulled section

**Test approach:** Inject a status buffer with multiple sections, call `SFunc('StageJump')` with different section names, verify cursor lands on the correct heading line.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test `gu` jumps cursor to the Unstaged section heading
- [ ] #2 Test `gU` jumps cursor to the Untracked section heading
- [ ] #3 Test `gp` jumps cursor to the Unpushed section heading
- [ ] #4 Test jump when target section does not exist (cursor stays put)
- [ ] #5 Test file in test/ named test_section_jumps.sh or included in test_navigation_maps.sh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All new tests pass locally via `bash test/run_tests.sh`
- [ ] #2 Existing tests still pass (no regressions)
- [ ] #3 vint lint passes: `vint -e plugin/ autoload/ ftplugin/ ftdetect/ syntax/`
- [ ] #4 Tests follow established patterns from helpers.sh (setup_jj_repo / run_nvim_test_in / pass / fail / cleanup / finish)
<!-- DOD:END -->
