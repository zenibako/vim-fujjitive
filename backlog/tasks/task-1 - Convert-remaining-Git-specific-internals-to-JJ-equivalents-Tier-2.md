---
id: TASK-1
title: Convert remaining Git-specific internals to JJ equivalents (Tier 2)
status: In Progress
assignee:
  - agent-2
created_date: '2026-02-11 20:45'
updated_date: '2026-02-12 22:01'
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
- [x] #1 No remaining references to `git add`, `git reset`, `git checkout`, `git rm`, `git clean`, `git stash` in operational code paths
- [x] #2 diff --cached references removed (no staging area in JJ)
- [x] #3 --pretty=format:fugitive log formatting replaced with JJ templates
- [x] #4 @{upstream} Git refspec syntax replaced with JJ revision syntax
- [x] #5 Git subcommand lists (s:subcommands_before_2_5 etc.) updated for JJ
- [x] #6 All remaining `fugitive_*` global/window variable names renamed to `fujjitive_*`
- [x] #7 s:CommitSubcommand --patch flag handling updated for JJ
- [x] #8 fujjitive#CommitComplete @{upstream} reference removed
- [x] #9 s:DoUnstageUnpushed Git rebase --interactive reference converted
- [x] #10 Design and implement proper rebase map equivalents for JJ workflow
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
# Implementation Plan (Phases 1-2, 4-8)\n\n## Phase 1: Mechanical renames — fugitive_* → fujjitive_*\nRename all remaining `fugitive_` variable/event names.\n\n## Phase 2: Remove staging-area concepts (--cached)\nRemove --cached flag handling in difftool, grep, and rm.\n\n## Phase 4: Replace Git log formatting\nReplace --pretty=format with JJ templates, update log parser.\n\n## Phase 5: Replace @{upstream} refspec syntax\nReplace with JJ revsets.\n\n## Phase 6: Update subcommand lists for JJ\nReplace s:subcommands_before_2_5 and completion helpers.\n\n## Phase 7: Update commit/rebase handling\nFix --patch terminal detection, convert rebase --interactive.\n\n## Phase 8: Remaining cleanup\nVersion messages, config paths, env vars, keywordprg, stash refs."
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Phase 3 (Git plumbing: update-index, hash-object, cat-file, ls-tree, ls-files) split out to TASK-2 as high-risk work requiring separate focus.
<!-- SECTION:NOTES:END -->
