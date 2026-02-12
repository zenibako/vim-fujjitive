---
id: TASK-2
title: >-
  Replace Git plumbing (update-index, hash-object, cat-file, ls-tree, ls-files)
  with JJ equivalents
status: To Do
assignee: []
created_date: '2026-02-12 21:54'
labels:
  - tech-debt
  - git-to-jj
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Split out from Task-1 Phase 3. The Git plumbing commands (update-index, hash-object, cat-file, ls-tree, ls-files, write-tree, rev-parse, merge-base, diff-files) underpin the File API in autoload/fujjitive.vim. These are high-risk changes since they're foundational to how the plugin reads/writes file content at specific revisions.

Key functions affected:
- s:UpdateIndex() (line 2264) - used by setfperm, writefile, delete, FileWriteCmd
- s:StdoutToFile / hash-object calls in fujjitive#writefile() (line 2339) and fujjitive#FileWriteCmd() (line 3039)
- s:BlobTemp() using cat-file (line 2308)
- s:TreeInfo() using ls-tree (line 2154)
- fujjitive#CompleteObject() using ls-files/ls-tree (lines 2508, 2520)
- fujjitive#BufReadCmd() using cat-file, write-tree, ls-files (lines 3076-3162)
- s:IsConflicted() using ls-files --unmerged (line 6505)
- Various rev-parse calls throughout

JJ doesn't have a staging area (index), so most index operations can be simplified — writes go directly to the working copy, reads use `jj file show`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 s:UpdateIndex() replaced or removed — no update-index calls remain
- [ ] #2 hash-object calls replaced with direct working-copy writes
- [ ] #3 s:StdoutToFile usage for index operations replaced
- [ ] #4 cat-file/ls-tree/ls-files calls replaced with JJ equivalents (jj file show, jj file list, etc.)
- [ ] #5 fujjitive#writefile() and fujjitive#FileWriteCmd() write directly to working copy
- [ ] #6 fujjitive#delete() uses direct file deletion or jj file untrack
- [ ] #7 s:BlobTemp() uses jj file show instead of cat-file
<!-- AC:END -->
