---
id: TASK-1
title: Convert remaining Git-specific internals to JJ equivalents (Tier 2)
status: To Do
assignee: []
created_date: '2026-02-11 20:45'
labels:
  - tech-debt
  - git-to-jj
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
After the Tier 1 keymap fix, there are still ~50+ lines of unconverted Git-specific internal logic in autoload/fujjitive.vim. These are lower-priority because they're in code paths that are less commonly triggered or are internal plumbing, but they should be addressed for correctness.

The Tier 1 fix (committed separately) covered:
- s, u, -, S, I, p, X keymaps (split/squash/toggle/interactive/discard)
- dd, dv, ds, dh, dp diff maps
- Commit maps (cv, cW, cf, cF, cs, cS, cn)
- Revert maps (crc, crn)
- Checkout map (coo)
- Stash maps (disabled with error messages)
- Rebase maps (ri/rf/ru/rp disabled; rw/rm/rd converted)
- s:bang_edits, file-open logic, CommitInteractive search patterns
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 No remaining references to `git add`, `git reset`, `git checkout`, `git rm`, `git clean`, `git stash` in operational code paths
- [ ] #2 s:StageApply() rewritten to not use `git apply --cached` or `--index` flags
- [ ] #3 s:StdoutToFile / update-index plumbing replaced or removed
- [ ] #4 git hash-object calls replaced with JJ equivalents or removed
- [ ] #5 diff --cached references removed (no staging area in JJ)
- [ ] #6 --pretty=format:fugitive log formatting replaced with JJ templates
- [ ] #7 @{upstream} Git refspec syntax replaced with JJ revision syntax
- [ ] #8 Git subcommand lists (s:subcommands_before_2_5 etc.) updated for JJ
- [ ] #9 All remaining `fugitive_*` global/window variable names renamed to `fujjitive_*`
- [ ] #10 s:CommitSubcommand --patch flag handling updated for JJ
- [ ] #11 fujjitive#CommitComplete @{upstream} reference removed
- [ ] #12 s:DoUnstageUnpushed Git rebase --interactive reference converted
- [ ] #13 Design and implement proper rebase map equivalents for JJ workflow
<!-- AC:END -->
