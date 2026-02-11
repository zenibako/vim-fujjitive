#!/usr/bin/env bash
# test/test_path_resolution.sh — Tests for FujjitiveJJDir() and FujjitiveFind().
#
# These tests create fake .jj/ directory structures so they do NOT require
# the jj binary.

source "$(dirname "$0")/helpers.sh"

_bold "Path resolution tests"

# ── Test: FujjitiveJJDir detects .jj directory ───────────────────────────────

FAKE_REPO="$(mktemp -d)"
mkdir -p "$FAKE_REPO/.jj/repo/store"

if run_nvim_test_in "$FAKE_REPO" <<'VIMSCRIPT'
" Touch a file so we have a buffer with a path
silent edit test_file.txt
let dir = FujjitiveJJDir()
if empty(dir)
  echoerr 'FujjitiveJJDir() returned empty in a .jj directory'
  cquit 1
endif
VIMSCRIPT
then pass "FujjitiveJJDir() detects .jj directory"
else fail "FujjitiveJJDir() detects .jj directory"
fi

rm -rf "$FAKE_REPO"

# ── Test: FujjitiveJJDir returns empty outside repo ──────────────────────────

NO_REPO="$(mktemp -d)"

if run_nvim_test_in "$NO_REPO" <<'VIMSCRIPT'
" In a directory with no .jj, should return empty
let dir = FujjitiveJJDir()
if !empty(dir)
  echoerr 'FujjitiveJJDir() should be empty outside repo, got: ' . dir
  cquit 1
endif
VIMSCRIPT
then pass "FujjitiveJJDir() returns empty outside a repo"
else fail "FujjitiveJJDir() returns empty outside a repo"
fi

rm -rf "$NO_REPO"

# ── Test: FujjitiveJJDir with explicit string argument ───────────────────────

FAKE_REPO="$(mktemp -d)"
mkdir -p "$FAKE_REPO/.jj/repo/store"

if run_nvim_test <<VIMSCRIPT
" Passing an explicit path should return a normalized form of it
let result = FujjitiveJJDir('${FAKE_REPO}/.jj')
if empty(result)
  echoerr 'FujjitiveJJDir(string) returned empty'
  cquit 1
endif
if result !~# '\.jj\$'
  echoerr 'FujjitiveJJDir(string) should end with .jj, got: ' . result
  cquit 1
endif
VIMSCRIPT
then pass "FujjitiveJJDir(string) returns normalized path"
else fail "FujjitiveJJDir(string) returns normalized path"
fi

rm -rf "$FAKE_REPO"

# ── Test: FujjitiveFind returns buffer number or path ────────────────────────

FAKE_REPO="$(mktemp -d)"
mkdir -p "$FAKE_REPO/.jj/repo/store"
echo "content" > "$FAKE_REPO/real_file.txt"

if run_nvim_test_in "$FAKE_REPO" <<'VIMSCRIPT'
silent edit real_file.txt
" FujjitiveFind with a path should return something
let result = FujjitiveFind(bufnr(''))
" Should not throw an error; basic smoke test
if type(result) != type('')
  echoerr 'FujjitiveFind() did not return a string, got type: ' . type(result)
  cquit 1
endif
VIMSCRIPT
then pass "FujjitiveFind() returns a string"
else fail "FujjitiveFind() returns a string"
fi

rm -rf "$FAKE_REPO"

finish
