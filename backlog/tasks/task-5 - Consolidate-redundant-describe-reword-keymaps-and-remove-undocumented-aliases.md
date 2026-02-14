---
id: TASK-5
title: Consolidate redundant describe/reword keymaps and remove undocumented aliases
status: In Progress
assignee: []
created_date: '2026-02-14 02:21'
updated_date: '2026-02-14 02:24'
labels:
  - ux
  - keymaps
  - cleanup
dependencies: []
references:
  - 'autoload/fujjitive.vim:7800-7809'
  - 'autoload/fujjitive.vim:7859'
  - 'doc/fujjitive.txt:497-595'
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Several keymaps for editing descriptions are redundant without clear differentiation:
- `ca` and `cw` both run `jj describe` on the working copy (identical behavior)
- `cW` and `rw` both run `jj describe -r <commit>` on the cursor commit (identical behavior)
- `cRa`, `cRe`, `cRw` (lines 7807-7809) are undocumented aliases that duplicate `ca`, `ce`, `cw`

This creates confusion about which keymap to use and adds maintenance burden. The redundancy should be resolved by picking canonical keymaps and deprecating the duplicates.

Canonical keymaps (keep as-is):
- `ca` → describe current working copy ("amend" mnemonic from fugitive, well-known)
- `cW` → describe commit under cursor (capital-W as "reWord target")

Deprecate with error messages:
- `cw` → point to `ca`
- `rw` → point to `cW`

Remove entirely (undocumented, no known users):
- `cRa`, `cRe`, `cRw`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 ca continues to run jj describe on the working copy
- [ ] #2 cW continues to run jj describe -r <commit> on the commit under the cursor
- [ ] #3 cw shows a deprecation message directing users to ca
- [ ] #4 rw shows a deprecation message directing users to cW
- [ ] #5 cRa, cRe, and cRw maps are removed entirely
- [ ] #6 cva and cvc (tab variants) continue to work unchanged
- [ ] #7 Help documentation (doc/fujjitive.txt) is updated: cw and rw entries marked as deprecated, cRa/cRe/cRw not present
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan\n\n### File 1: autoload/fujjitive.vim — s:MapGitOps()\n1. Deprecate `cw` (line 7803) → echoerr pointing to `ca`\n2. Remove `cRa`, `cRe`, `cRw` (lines 7807-7809) entirely\n3. Deprecate `rw` (line 7859) → echoerr pointing to `cW`\n\n### File 2: doc/fujjitive.txt\n4. Update `cw` entry to show deprecation\n5. Update `rw` entry to show deprecation"
<!-- SECTION:PLAN:END -->
