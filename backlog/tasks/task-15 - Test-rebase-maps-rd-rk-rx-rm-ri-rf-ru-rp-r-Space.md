---
id: TASK-15
title: 'Test rebase maps (rd/rk/rx, rm, ri, rf, ru/rp, r<Space>)'
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
  - 'autoload/fujjitive.vim:7994'
  - 'autoload/fujjitive.vim:7843'
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add test coverage for the rebase-related keymaps defined in `s:MapGitOps()` (lines 7994-8009).

**Maps and handlers:**
- `rd`/`rk`/`rx` (lines 8002-8004): `s:SquashCommand("JJ abandon")` — abandons commit under cursor
- `rm` (line 8001): `s:SquashCommand("JJ edit")` — edits commit under cursor (same as `co`)
- `ri` (line 7996): Populates command line with `:JJ rebase -r <change_id> -d ` for user input
- `rf` (line 7997): `s:SquashCommand("JJ squash --into")` — squash into specific revision
- `ru`/`rp` (lines 7998-7999): `s:SquashCommand("JJ rebase -b", "-d 'trunk()'")` — rebase onto trunk
- `r<Space>` (line 7994): Populates command line with `:JJ rebase ` for free-form input

**Test approach:** Inject commit lines in status buffer, call `SFunc('SquashCommand')` or check map definitions. For `rd`/`rk`/`rx`, verify the abandon command is constructed. For `ri`/`r<Space>`, verify command line population.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test `rd` on a commit line constructs `:JJ abandon <change_id>`
- [ ] #2 Test `rk` and `rx` behave identically to `rd`
- [ ] #3 Test `rm` on a commit line constructs `:JJ edit <change_id>`
- [ ] #4 Test `rf` on a commit line constructs `:JJ squash --into <change_id>`
- [ ] #5 Test `ru` constructs `:JJ rebase -b <change_id> -d 'trunk()'`
- [ ] #6 Test `r<Space>` mapping starts with `:JJ rebase `
- [ ] #7 Test file in test/ named test_rebase_maps.sh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All new tests pass locally via `bash test/run_tests.sh`
- [ ] #2 Existing tests still pass (no regressions)
- [ ] #3 vint lint passes: `vint -e plugin/ autoload/ ftplugin/ ftdetect/ syntax/`
- [ ] #4 Tests follow established patterns from helpers.sh (setup_jj_repo / run_nvim_test_in / pass / fail / cleanup / finish)
<!-- DOD:END -->
