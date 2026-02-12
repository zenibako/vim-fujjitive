---
id: TASK-2
title: Implement interactive splitting via terminal mode for S/I keymaps
status: Done
assignee: []
created_date: '2026-02-12 21:37'
updated_date: '2026-02-12 21:59'
labels:
  - feature
  - keymaps
dependencies: []
references:
  - 'autoload/fujjitive.vim:3786 (wants_terminal expression)'
  - 'autoload/fujjitive.vim:3789-3803 (terminal mode implementation)'
  - 'autoload/fujjitive.vim:5248 (s:StagePatch calling tab JJ split)'
  - 'autoload/fujjitive.vim:595 (s:HasOpt function)'
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The `S` and `I` keymaps in the status buffer invoke `tab JJ split --interactive`, but `jj split` is not in the `wants_terminal` guard list in `fujjitive#Command()` (line ~3787). This causes the command to be routed to the background job path instead of opening a real terminal buffer, so the interactive TUI never renders.

The fix is to add `'split'` to the `s:HasOpt` subcommand guard lists in the `wants_terminal` expression so that `split --interactive` (and `split` with no filesets, which defaults to interactive) opens in a Vim/Neovim terminal buffer. The terminal infrastructure already supports both Neovim (`termopen()`) and Vim 8+ (`term_start()`), so this is NOT a Neovim-only feature.

Additionally, `jj split` without any filesets is interactive by default (per `jj split --help`: "This is the default if no filesets are provided"). The `wants_terminal` logic should account for this — when the subcommand is `split` and no filesets are given, it should also route to the terminal path.

After the terminal closes, the status buffer should be reloaded to reflect the new state.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Pressing S in the status buffer opens `jj split --interactive` in a terminal buffer (new tab)
- [x] #2 Pressing I in the status buffer also opens `jj split --interactive` in a terminal buffer
- [x] #3 Visual-mode S and I operate on selected files: `jj split --interactive -- <files>`
- [x] #4 `jj split` with no filesets (bare split) also routes to terminal mode since it is interactive by default
- [x] #5 Works in both Neovim (termopen) and Vim 8+ (term_start)
- [x] #6 The `tab` modifier is respected — terminal opens in a new tab
- [x] #7 Status buffer reloads after the terminal command completes
- [x] #8 The `--tool` flag on split also triggers terminal mode
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### 1. Add `split` to `wants_terminal` guard (line ~3786)

Add `'split'` to the `s:HasOpt` subcommand guard lists so that `split -i`/`--interactive`/`--tool` routes to terminal mode. Also handle bare `split` (no filesets = interactive by default).

The `wants_terminal` expression becomes:
```vim
let wants_terminal = type(pager) ==# type('') ||
      \\ (s:HasOpt(args, ['add', 'checkout', 'commit', 'reset', 'restore', 'stage', 'restore', 'split'], '-p', '--patch', '-i', '--interactive', '--tool') ||
      \\ s:HasOpt(args, ['add', 'clean', 'stage'], '-i', '--interactive') ||
      \\ (get(args, 0, '') ==# 'split' && !s:HasOpt(args, '--', '.'))) && pager is# 0
```

Actually, simpler: `jj split` without filesets is interactive by default. But we also need to handle `--tool`. The cleanest approach:
- Add `'split'` to the first HasOpt list with `-i`, `--interactive`, `--tool` flags
- Add a bare `split` check: if subcommand is `split` and no `--` separator with paths after it

### 2. Add `fujjitive#DidChange` to terminal close callback

The terminal path (lines 3789-3803) doesn't include `fujjitive#DidChange()`. Add it to the `after` string before the terminal branch, or use a TermClose autocmd.

For Neovim: `termopen()` accepts an `on_exit` callback.
For Vim 8+: `term_start()` accepts an `exit_cb` option.

Simplest approach: append `fujjitive#DidChange` to the `assign` string so it runs when the user closes the terminal buffer (via BufDelete/BufWipeout autocmd on the terminal buffer).

### 3. Verify s:StagePatch flow

`s:StagePatch` already does `execute 'tab JJ split --interactive'` which goes through `fujjitive#Command`. After the terminal routing fix, this will open a terminal tab. The `return s:ReloadStatus()` call after `execute` will run immediately (before the terminal finishes), which is fine - the DidChange callback on terminal close will handle the reload.

### Files changed
- `autoload/fujjitive.vim`: wants_terminal expression + terminal close callback
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
## Summary

Added `'split'` to the `wants_terminal` guard in `fujjitive#Command()` so that `jj split --interactive`, `jj split --tool`, and bare `jj split` (interactive by default when no filesets given) route to the terminal path in both Neovim (`termopen()`) and Vim 8+ (`term_start()`).

Added `autocmd TermClose <buffer> ++once call fujjitive#DidChange(dir)` to both terminal code paths so the status buffer reloads after the terminal command completes.

Committed as the change after `c9ebbb72`.
<!-- SECTION:FINAL_SUMMARY:END -->
