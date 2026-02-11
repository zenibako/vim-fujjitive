#!/usr/bin/env bash
# test/test_statusline.sh — Tests for fujjitive#Statusline().
#
# Validates:
#   - Returns [Git(...)] format inside a repo
#   - Returns empty string outside a repo

source "$(dirname "$0")/helpers.sh"

_bold "Statusline tests"

# ── Prereq ──────────────────────────────────────────────────────────────────

if ! command -v jj &>/dev/null; then
  _bold "  SKIP: jj not found — skipping statusline tests that need jj"

  # We can still test the "outside repo" case
  NO_REPO="$(mktemp -d)"

  if run_nvim_test_in "$NO_REPO" <<'VIMSCRIPT'
let result = fujjitive#Statusline()
if result !=# ''
  echoerr 'Expected empty statusline outside repo, got: ' . result
  cquit 1
endif
VIMSCRIPT
  then pass "fujjitive#Statusline() returns empty outside repo"
  else fail "fujjitive#Statusline() returns empty outside repo"
  fi

  rm -rf "$NO_REPO"
  finish
fi

# ── Test: Statusline returns [Git(...)] inside a jj repo ────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
let result = fujjitive#Statusline()

if result !~# '^\[Git'
  echoerr 'Statusline should start with [Git, got: ' . result
  cquit 1
endif
if result !~# '\]$'
  echoerr 'Statusline should end with ], got: ' . result
  cquit 1
endif
VIMSCRIPT
then pass "fujjitive#Statusline() returns [Git(...)] in repo"
else fail "fujjitive#Statusline() returns [Git(...)] in repo"
fi

cleanup

# ── Test: Statusline returns empty outside a repo ────────────────────────────

NO_REPO="$(mktemp -d)"

if run_nvim_test_in "$NO_REPO" <<'VIMSCRIPT'
let result = fujjitive#Statusline()
if result !=# ''
  echoerr 'Expected empty statusline outside repo, got: ' . result
  cquit 1
endif
VIMSCRIPT
then pass "fujjitive#Statusline() returns empty outside repo"
else fail "fujjitive#Statusline() returns empty outside repo"
fi

rm -rf "$NO_REPO"

# ── Test: Lowercase alias works the same ─────────────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
let upper = fujjitive#Statusline()
let lower = fujjitive#statusline()
if upper !=# lower
  echoerr 'Statusline() != statusline(): ' . upper . ' vs ' . lower
  cquit 1
endif
VIMSCRIPT
then pass "fujjitive#statusline() alias matches fujjitive#Statusline()"
else fail "fujjitive#statusline() alias matches fujjitive#Statusline()"
fi

cleanup

finish
