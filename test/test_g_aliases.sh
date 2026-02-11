#!/usr/bin/env bash
# test/test_g_aliases.sh — Tests for the :G command (git-to-jj alias routing).
#
# Validates:
#   - :G command is defined
#   - :G routes git-bridge commands (push, fetch, etc.) through jj git
#   - :G routes direct equivalents (status, diff, log, etc.) to jj directly
#   - :G routes renamed commands (checkout → edit)
#   - Tab completion includes all mapped commands

source "$(dirname "$0")/helpers.sh"

_bold ":G alias tests"

# ── Test: :G command is defined (no jj required) ────────────────────────────

if run_nvim_test <<'VIMSCRIPT'
" :G should be defined by the plugin
if exists(':G') != 2
  echoerr ':G command is not defined'
  cquit 1
endif
VIMSCRIPT
then pass ":G command is defined"
else fail ":G command is defined"
fi

# ── Test: :G completion includes expected commands ──────────────────────────

if run_nvim_test <<'VIMSCRIPT'
" Force autoload so the completion function is available
call fujjitive#GitVersion()

let completions = fujjitive#GitComplete('', 'G ', 2)

" Check git-bridge commands
for cmd in ['push', 'fetch', 'clone', 'remote']
  if index(completions, cmd) < 0
    echoerr 'Missing git-bridge command in completion: ' . cmd . '. Got: ' . string(completions)
    cquit 1
  endif
endfor

" Check direct-equivalent commands
for cmd in ['status', 'diff', 'log', 'show', 'commit', 'blame']
  if index(completions, cmd) < 0
    echoerr 'Missing direct command in completion: ' . cmd . '. Got: ' . string(completions)
    cquit 1
  endif
endfor

" Check renamed commands
for cmd in ['checkout', 'switch']
  if index(completions, cmd) < 0
    echoerr 'Missing renamed command in completion: ' . cmd . '. Got: ' . string(completions)
    cquit 1
  endif
endfor
VIMSCRIPT
then pass ":G completion includes git-bridge, direct, and renamed commands"
else fail ":G completion includes git-bridge, direct, and renamed commands"
fi

# ── Test: :G completion filters by prefix ───────────────────────────────────

if run_nvim_test <<'VIMSCRIPT'
call fujjitive#GitVersion()

let completions = fujjitive#GitComplete('pu', 'G pu', 4)
if index(completions, 'push') < 0
  echoerr 'Completion for "pu" should include "push". Got: ' . string(completions)
  cquit 1
endif
if index(completions, 'fetch') >= 0
  echoerr 'Completion for "pu" should not include "fetch". Got: ' . string(completions)
  cquit 1
endif
VIMSCRIPT
then pass ":G completion filters by prefix correctly"
else fail ":G completion filters by prefix correctly"
fi

# ── Tests below require jj ──────────────────────────────────────────────────

if ! command -v jj &>/dev/null; then
  _bold "  SKIP: jj not found — skipping integration tests"
  finish
fi

# ── Test: :G status routes to jj status ─────────────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
G status

" :G status should behave like :JJ status (opens the summary buffer)
" The fujjitive status buffer sets filetype to fujjitive
if &filetype !=# 'fujjitive'
  echoerr 'Expected filetype=fujjitive from :G status, got: ' . &filetype
  cquit 1
endif
VIMSCRIPT
then pass ":G status opens fujjitive status buffer"
else fail ":G status opens fujjitive status buffer"
fi

cleanup

# ── Test: :G log routes to jj log ───────────────────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
G log

" Should produce log output (filetype=git for pager commands)
if &filetype !=# 'git'
  echoerr 'Expected filetype=git from :G log, got: ' . &filetype
  cquit 1
endif

let content = join(getline(1, '$'), "\n")
if content !~# 'initial commit'
  echoerr ':G log does not contain "initial commit". Content: ' . content
  cquit 1
endif
VIMSCRIPT
then pass ":G log shows commit history"
else fail ":G log shows commit history"
fi

cleanup

# ── Test: :G diff routes to jj diff ─────────────────────────────────────────

setup_jj_repo
echo "modified content" >> "$TEST_REPO/file.txt"

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
G diff

let content = join(getline(1, '$'), "\n")
if content !~# 'file\.txt'
  echoerr ':G diff does not reference file.txt. Content: ' . content
  cquit 1
endif
VIMSCRIPT
then pass ":G diff shows changes referencing modified files"
else fail ":G diff shows changes referencing modified files"
fi

cleanup

# ── Test: :G commit routes to jj commit ─────────────────────────────────────

setup_jj_repo

pre_change="$(jj log -r @ --no-graph -T 'change_id' -R "$TEST_REPO" 2>/dev/null)"

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
G commit -m "committed via :G"
sleep 2
VIMSCRIPT
then
  post_change="$(jj log -r @ --no-graph -T 'change_id' -R "$TEST_REPO" 2>/dev/null)"
  if [[ "$post_change" != "$pre_change" ]]; then
    parent_desc="$(jj log -r '@-' --no-graph -T 'description' -R "$TEST_REPO" 2>/dev/null)"
    if [[ "$parent_desc" == *"committed via :G"* ]]; then
      pass ":G commit -m creates new change with correct message"
    else
      fail ":G commit -m creates new change with correct message" "parent desc: $parent_desc"
    fi
  else
    fail ":G commit -m creates new change" "change_id did not change: $pre_change"
  fi
else
  fail ":G commit -m creates new change" "nvim exited non-zero"
fi

cleanup

# ── Test: :G describe routes to jj describe ─────────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
G describe -m "described via :G"
sleep 2
VIMSCRIPT
then
  desc="$(jj log -r @ --no-graph -T 'description' -R "$TEST_REPO" 2>/dev/null)"
  if [[ "$desc" == *"described via :G"* ]]; then
    pass ":G describe -m sets working copy description"
  else
    fail ":G describe -m sets working copy description" "got description: $desc"
  fi
else
  fail ":G describe -m sets working copy description" "nvim exited non-zero"
fi

cleanup

finish
