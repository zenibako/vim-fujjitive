---
id: TASK-1
title: Convert remaining Git-specific internals to JJ equivalents (Tier 2)
status: Done
assignee:
  - agent-2
created_date: '2026-02-11 20:45'
updated_date: '2026-02-12 22:02'
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

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
# Summary\n\nConverted ~50+ lines of remaining Git-specific internal logic to JJ equivalents across autoload/fujjitive.vim and plugin/fujjitive.vim.\n\n## Changes\n\n### Variable/Event Renames (Phase 1)\n- Renamed all `fugitive_*` variables to `fujjitive_*`: `w:fugitive_diff_restore`, `g:fugitive_diffsplit_directional_fit`, `g:fugitive_legacy_commands`, `w:fugitive_leave`, `g:fugitive_dynamic_colors`, `g:fugitive_browse_handlers`, `g:fugitive_url_origins`, `g:fugitive_no_maps`\n- Renamed grep events: `grep-fugitive` → `grep-fujjitive`\n- Renamed log format prefix: `fugitive` → `fujjitive` in both format and parser\n\n### Staging Area Removal (Phase 2)\n- Removed `--cached` flag handling in difftool, grep, and rm commands\n- Replaced `rm --cached` with `file untrack` for JJ\n\n### Log Formatting (Phase 4)\n- Replaced all `--pretty=format:` Git log formatting with JJ templates\n- Updated `s:TreeInfo()`, `fujjitive#CommitComplete()`, `fujjitive#BufReadCmd()`, `fujjitive#LogCommand()`\n- Updated `s:LogParse()` to match new format prefix\n- Removed stash listing (JJ has no stash)\n\n### Refspec Syntax (Phase 5)\n- Replaced `@{upstream}..` with JJ revset `::@ & mutable()`\n\n### Subcommand Lists (Phase 6)\n- Replaced `s:subcommands_before_2_5` Git command list with JJ subcommands\n- Simplified `s:CompletableSubcommands()` for JJ\n- Removed `--git-completion-helper`, `--exec-path`, `--list-cmds` references\n\n### Commit/Rebase Handling (Phase 7)\n- Updated terminal detection for JJ interactive commands (split, diffedit, resolve)\n- Added `--split` as alias for `--patch` in commit subcommand\n- Implemented proper rebase maps: `ri` (rebase -r -d), `rf` (squash --into), `ru`/`rp` (rebase -b -d trunk())\n- Converted `s:DoUnstageUnpushed` from `rebase --interactive` to `rebase -r -d`\n- Updated MergeSubcommand to point users to `jj new REV1 REV2`\n- Simplified RebaseSubcommand (JJ rebase is non-interactive)\n\n### Cleanup (Phase 8)\n- Version message: \"Git 1.8.5\" → \"JJ 0.9\"\n- Worktree error: Updated for JJ terminology\n- Config paths: Replaced Git config paths with JJ config paths\n- Environment: `GIT_WORK_TREE` → `JJ_WORK_TREE`\n- Keywordprg: Replaced `--git-dir=` with JJ `-R` flag\n- Args parsing: Added `-R` flag recognition alongside `--git-dir=`\n\n## Deferred\n\nHigh-risk Git plumbing replacement (update-index, hash-object, cat-file, ls-tree, ls-files) split to TASK-2."
<!-- SECTION:FINAL_SUMMARY:END -->
