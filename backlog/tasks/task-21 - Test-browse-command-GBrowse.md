---
id: TASK-21
title: 'Test browse command (:GBrowse)'
status: To Do
assignee: []
created_date: '2026-03-05 16:45'
labels:
  - test
  - ex-command
milestone: m-2
dependencies: []
references:
  - 'autoload/fujjitive.vim:7449'
  - 'plugin/fujjitive.vim:641'
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add test coverage for the `:GBrowse` command which generates URLs for the current file/commit.

**Handler:** `fujjitive#BrowseCommand()` (line 7449). Resolves current file/commit/ref to a URL via `g:fujjitive_browse_handlers`. Determines remote URL, commit hash, path, type, and line range. Calls each handler in sequence. With `!` bang, copies URL to clipboard instead.

**Test approach:** This is harder to test in isolation since it depends on `g:fujjitive_browse_handlers` being configured. Test the URL resolution logic by mocking/setting up a handler function, or test that it errors gracefully when no handler is configured. With `!` bang, verify the echoed URL format.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test `:GBrowse` with no handlers configured shows an appropriate error
- [ ] #2 Test `:GBrowse!` echoes a URL (when handler is configured)
- [ ] #3 Test the remote URL resolution works with a git remote
- [ ] #4 Test file in test/ named test_browse.sh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All new tests pass locally via `bash test/run_tests.sh`
- [ ] #2 Existing tests still pass (no regressions)
- [ ] #3 vint lint passes: `vint -e plugin/ autoload/ ftplugin/ ftdetect/ syntax/`
- [ ] #4 Tests follow established patterns from helpers.sh (setup_jj_repo / run_nvim_test_in / pass / fail / cleanup / finish)
<!-- DOD:END -->
