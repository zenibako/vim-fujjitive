---
id: TASK-11
title: 'Test navigation maps ((, ), [c, ]c, [/, ]/, [[, ]])'
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
  - 'autoload/fujjitive.vim:4742'
  - 'autoload/fujjitive.vim:4804'
  - 'autoload/fujjitive.vim:4828'
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add test coverage for the navigation keymaps in status and diff buffers. These are cursor movement functions that help users navigate between items, hunks, files, and sections.

**Handlers (all direct cursor movement via `search()`, no feedkeys):**
- `(` / `)`: `s:PreviousItem()` / `s:NextItem()` (lines 4814/4804) — navigate between file entries, commits, or `@@` hunks
- `[c` / `]c`: `s:PreviousHunk()` / `s:NextHunk()` (lines 4763/4742) — navigate between diff hunks, auto-expands inline diffs
- `[/` / `]/`: `s:PreviousFile()` / `s:NextFile()` (lines 4792/4781) — navigate between files
- `[[` / `]]`: `s:PreviousSection()` / `s:NextSection()` (lines 4846/4828) — navigate between sections

**Test approach:** Create a status buffer with multiple sections, files, and optionally expanded inline diffs. Call `SFunc('NextItem')` etc. and verify `line('.')` moves to the expected position.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test `)` moves cursor to the next file/item entry
- [ ] #2 Test `(` moves cursor to the previous file/item entry
- [ ] #3 Test `]c` moves to the next hunk header or file
- [ ] #4 Test `[c` moves to the previous hunk header or file
- [ ] #5 Test `]/` moves to the next file entry
- [ ] #6 Test `[/` moves to the previous file entry
- [ ] #7 Test `]]` moves to the next section heading
- [ ] #8 Test `[[` moves to the previous section heading
- [ ] #9 Test wrapping behavior at boundaries (first/last item)
- [ ] #10 Test file in test/ named test_navigation_maps.sh
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All new tests pass locally via `bash test/run_tests.sh`
- [ ] #2 Existing tests still pass (no regressions)
- [ ] #3 vint lint passes: `vint -e plugin/ autoload/ ftplugin/ ftdetect/ syntax/`
- [ ] #4 Tests follow established patterns from helpers.sh (setup_jj_repo / run_nvim_test_in / pass / fail / cleanup / finish)
<!-- DOD:END -->
