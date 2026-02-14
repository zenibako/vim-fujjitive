---
id: TASK-6
title: Fix jj show / commit object viewing from status buffer
status: In Progress
assignee: []
created_date: '2026-02-14 12:53'
labels:
  - bug
  - jj-compat
dependencies: []
references:
  - 'autoload/fujjitive.vim:3163'
  - 'autoload/fujjitive.vim:4496'
  - 'autoload/fujjitive.vim:2604'
  - test/test_jj_show.sh
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Three interrelated bugs prevent viewing commit objects in vim-fujjitive when using jj (not git):

1. **BufReadCmd uses `cat-file -t`** (line 3163) to determine object type, but jj doesn't have `cat-file`. This makes `:Gedit <hash>` produce an empty buffer.

2. **`s:FormatLog` doesn't include commit_id** — the formatted log line only shows the change_id (e.g. `xv·unvwnm`), so `s:StageInfo` regex `[0-9a-f]{4,}` can't extract a hex commit hash from Ancestors lines.

3. **`<CR>` on commit lines does nothing** — consequence of bug 2. `info.commit` is always empty, so `s:CfilePorcelain` returns `['']`.

These bugs were discovered and confirmed by test/test_jj_show.sh (3 failing tests).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 `:Gedit <commit-hash>` opens a buffer with commit metadata (author, description) instead of an empty buffer
- [ ] #2 `<CR>` on a commit line in the Ancestors section of the status buffer navigates to the commit object
- [ ] #3 s:StageInfo extracts a usable commit identifier from jj-formatted log lines in the status buffer
- [ ] #4 All 9 tests in test/test_jj_show.sh pass
- [ ] #5 All pre-existing tests continue to pass
<!-- AC:END -->
