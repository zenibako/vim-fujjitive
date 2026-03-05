---
id: TASK-19
title: 'Test quickfix integration (:Gclog, :Gllog)'
status: To Do
assignee: []
created_date: '2026-03-05 16:45'
labels:
  - test
  - ex-command
  - quickfix
milestone: m-2
dependencies: []
references:
  - 'autoload/fujjitive.vim:6044'
  - 'autoload/fujjitive.vim:1562'
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add test coverage for quickfix/location list integration with jj log.

**Handler:** `fujjitive#LogCommand()` (line 6044). Builds a `jj log --no-graph -T <template>` command and populates the quickfix (`:Gclog`) or location list (`:Gllog`) via `s:QuickfixStream()` (line 1562).

**Template:** Outputs `fujjitive <change_id> <parents>\t<commit_id> <description>` format, parsed by `s:LogParse()` (line 6964).

**Test approach:** Run `:Gclog` in a repo with several commits, verify the quickfix list is populated with entries that have valid file/line info. Run `:Gllog` and verify location list.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test `:Gclog` populates the quickfix list with commit entries
- [ ] #2 Test `:Gllog` populates the location list with commit entries
- [ ] #3 Test quickfix entries contain valid commit descriptions
- [ ] #4 Test file in test/ named test_quickfix.sh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All new tests pass locally via `bash test/run_tests.sh`
- [ ] #2 Existing tests still pass (no regressions)
- [ ] #3 vint lint passes: `vint -e plugin/ autoload/ ftplugin/ ftdetect/ syntax/`
- [ ] #4 Tests follow established patterns from helpers.sh (setup_jj_repo / run_nvim_test_in / pass / fail / cleanup / finish)
<!-- DOD:END -->
