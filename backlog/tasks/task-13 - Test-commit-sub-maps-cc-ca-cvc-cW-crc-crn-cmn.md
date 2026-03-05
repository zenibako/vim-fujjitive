---
id: TASK-13
title: 'Test commit sub-maps (cc, ca, cvc, cW, crc/crn, cmn)'
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
  - 'autoload/fujjitive.vim:7934'
  - 'autoload/fujjitive.vim:7832'
  - test/test_describe_commit.sh
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add test coverage for the commit-related keymaps beyond basic describe/commit. These are defined in `s:MapGitOps()` (lines 7934-8010).

**Maps and handlers:**
- `cc` (line 7944): `:JJ commit` — direct ex command
- `ca` (line 7943): `:JJ describe` — direct ex command
- `cvc` (line 7949): `:tab JJ describe` — opens describe in a new tab
- `cW` (line 7947): `:JJ describe -r <SquashArgument()>` — rewrites description of commit under cursor. Uses `s:SquashArgument()` (line 7832) to extract revision from cursor line.
- `crc`/`crn` (lines 7961-7962): `s:SquashCommand("JJ backout -r")` — creates a backout of the commit under cursor
- `cmn` (line 7967): `s:SquashCommand("JJ new")` — creates a new change on the commit under cursor

**Key helper:** `s:SquashArgument()` (line 7832) parses the current line for a change ID. In fujjitive buffers, it looks for change IDs or ref header values.

**Test approach:** For `cc`/`ca`/`cvc`/`ce`, test with real repo state. For `cW`/`crc`/`crn`/`cmn`, inject status buffer content with commit lines, call `SFunc('SquashCommand')` or the map directly, and verify the correct command is constructed.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test `cc` mapping points to `:JJ commit`
- [ ] #2 Test `ca` mapping points to `:JJ describe`
- [ ] #3 Test `cvc` mapping points to `:tab JJ describe`
- [ ] #4 Test `cW` constructs `:JJ describe -r <change_id>` with the change ID from the cursor line
- [ ] #5 Test `crc` constructs `:JJ backout -r <change_id>` from the cursor line
- [ ] #6 Test `cmn` constructs `:JJ new <change_id>` from the cursor line
- [ ] #7 Test `s:SquashArgument()` correctly extracts change IDs from status buffer commit lines
- [ ] #8 Test file in test/ named test_commit_maps.sh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All new tests pass locally via `bash test/run_tests.sh`
- [ ] #2 Existing tests still pass (no regressions)
- [ ] #3 vint lint passes: `vint -e plugin/ autoload/ ftplugin/ ftdetect/ syntax/`
- [ ] #4 Tests follow established patterns from helpers.sh (setup_jj_repo / run_nvim_test_in / pass / fail / cleanup / finish)
<!-- DOD:END -->
