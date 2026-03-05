---
id: TASK-20
title: 'Test grep commands (:Ggrep, :Glgrep)'
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
  - 'autoload/fujjitive.vim:5839'
  - 'autoload/fujjitive.vim:5749'
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add test coverage for the grep integration commands.

**Handler:** `s:GrepSubcommand()` (line 5839). Runs `grep --no-color --full-name -n` + args via `s:SystemList()`, parses output with `s:GrepParseLine()` (line 5749), and populates quickfix (`:Ggrep`) or location list (`:Glgrep`).

**Test approach:** Create a repo with files containing known content, run `:Ggrep pattern`, verify quickfix list contains correct file/line matches.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test `:Ggrep pattern` populates quickfix with matching file:line entries
- [ ] #2 Test `:Glgrep pattern` populates location list instead
- [ ] #3 Test results point to correct files and line numbers
- [ ] #4 Test file in test/ named test_grep.sh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All new tests pass locally via `bash test/run_tests.sh`
- [ ] #2 Existing tests still pass (no regressions)
- [ ] #3 vint lint passes: `vint -e plugin/ autoload/ ftplugin/ ftdetect/ syntax/`
- [ ] #4 Tests follow established patterns from helpers.sh (setup_jj_repo / run_nvim_test_in / pass / fail / cleanup / finish)
<!-- DOD:END -->
