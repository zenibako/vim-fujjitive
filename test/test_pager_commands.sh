#!/usr/bin/env bash
# test/test_pager_commands.sh — Tests for pager commands (:J log, :JJ diff).
#
# Validates:
#   - :J log opens a buffer with filetype=git and content
#   - :JJ diff produces a buffer with diff output

source "$(dirname "$0")/helpers.sh"

_bold "Pager command tests"

# ── Prereq ──────────────────────────────────────────────────────────────────

if ! command -v jj &>/dev/null; then
  _bold "  SKIP: jj not found — skipping all pager command tests"
  finish
fi

# ── Test: :J log opens buffer with filetype=git ──────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J log

if &filetype !=# 'git'
  echoerr 'Expected filetype=git, got: ' . &filetype
  cquit 1
endif

" Buffer should have content (at least the initial commit)
if line('$') <= 1 && getline(1) ==# ''
  echoerr 'Log buffer is empty'
  cquit 1
endif
VIMSCRIPT
then pass ":J log opens buffer with filetype=git and content"
else fail ":J log opens buffer with filetype=git and content"
fi

cleanup

# ── Test: :J log contains commit descriptions ────────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J log

let content = join(getline(1, '$'), "\n")

" Should contain our test commit description
if content !~# 'initial commit'
  echoerr 'Log does not contain "initial commit". Content: ' . content
  cquit 1
endif
VIMSCRIPT
then pass ":J log contains commit descriptions"
else fail ":J log contains commit descriptions"
fi

cleanup

# ── Test: :JJ diff produces diff-like output ─────────────────────────────────

setup_jj_repo

# Make a change so there's something to diff
echo "new line" >> "$TEST_REPO/file.txt"

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
JJ diff

let content = join(getline(1, '$'), "\n")

" Diff output should contain diff markers or file references
if content !~# 'file\.txt'
  echoerr 'Diff does not reference file.txt. Content: ' . content
  cquit 1
endif
VIMSCRIPT
then pass ":JJ diff produces output referencing changed files"
else fail ":JJ diff produces output referencing changed files"
fi

cleanup

finish
