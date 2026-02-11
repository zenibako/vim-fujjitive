#!/usr/bin/env bash
# test/helpers.sh — Shared helpers for vim-fujjitive test scripts.
#
# Source this file at the top of each test script:
#   source "$(dirname "$0")/helpers.sh"
#
# Provides:
#   setup_jj_repo      Create a temp jj repo with a test file
#   cleanup             Remove the temp repo
#   run_nvim_test       Run VimScript in headless Neovim with the plugin loaded
#   run_nvim_test_in    Same, but cd into a directory first
#   RESOLVE_SID_VIM     VimScript snippet to resolve autoload SID
#   pass / fail         Colored test result output
#   finish              Print summary and exit

set -euo pipefail

# ── Paths ───────────────────────────────────────────────────────────────────

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_REPO=""

# ── Environment ─────────────────────────────────────────────────────────────

export JJ_USER="${JJ_USER:-Test User}"
export JJ_EMAIL="${JJ_EMAIL:-test@example.com}"

# ── Counters ────────────────────────────────────────────────────────────────

_PASS=0
_FAIL=0
_FAILURES=()

# ── Output helpers ──────────────────────────────────────────────────────────

_green()  { printf '\033[32m%s\033[0m\n' "$*"; }
_red()    { printf '\033[31m%s\033[0m\n' "$*"; }
_bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

pass() {
  _PASS=$((_PASS + 1))
  _green "  PASS: $1"
}

fail() {
  _FAIL=$((_FAIL + 1))
  _FAILURES+=("$1")
  _red "  FAIL: $1"
  if [[ -n "${2:-}" ]]; then
    printf '        %s\n' "$2"
  fi
}

# Print summary and exit with appropriate code. Call at end of each test script.
finish() {
  echo ""
  if [[ $_FAIL -eq 0 ]]; then
    _green "All $_PASS tests passed."
  else
    _red "$_FAIL failed, $_PASS passed."
    for f in "${_FAILURES[@]}"; do
      _red "  - $f"
    done
  fi
  [[ $_FAIL -eq 0 ]]
}

# ── Repo setup / teardown ──────────────────────────────────────────────────

setup_jj_repo() {
  TEST_REPO="$(mktemp -d)"
  (
    cd "$TEST_REPO"
    jj git init --quiet 2>/dev/null || jj git init
    echo "test content" > file.txt
    echo "other content" > other.txt
    jj describe -m "test: initial commit" 2>/dev/null
  )
  export TEST_REPO
}

cleanup() {
  if [[ -n "$TEST_REPO" && -d "$TEST_REPO" ]]; then
    rm -rf "$TEST_REPO"
  fi
  TEST_REPO=""
}

# ── Neovim runner ───────────────────────────────────────────────────────────

# Run VimScript in headless Neovim with the plugin loaded.
# The script is read from stdin (use a heredoc).
# Exits 0 if Neovim exits 0, non-zero otherwise.
#
# Usage:
#   run_nvim_test <<'VIMSCRIPT'
#     if 1 + 1 != 2 | cquit 1 | endif
#     qall!
#   VIMSCRIPT
run_nvim_test() {
  local timeout="${NVIM_TIMEOUT:-10}"
  timeout "$timeout" nvim --headless -u NONE -N \
    --cmd "set rtp^=${PLUGIN_DIR}" \
    --cmd 'runtime plugin/fujjitive.vim' \
    +'source /dev/stdin' \
    +'qall!' \
    2>&1
}

# Like run_nvim_test but executes Neovim inside the given directory.
#
# Usage:
#   run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
#     ...
#   VIMSCRIPT
run_nvim_test_in() {
  local dir="$1"
  local timeout="${NVIM_TIMEOUT:-10}"
  timeout "$timeout" nvim --headless -u NONE -N \
    --cmd "set rtp^=${PLUGIN_DIR}" \
    --cmd "cd ${dir}" \
    --cmd 'runtime plugin/fujjitive.vim' \
    +'source /dev/stdin' \
    +'qall!' \
    2>&1
}

# ── VimScript snippets (paste into heredocs) ────────────────────────────────

# Resolves the SID for autoload/fujjitive.vim so you can call script-local
# functions. After this runs you can use:
#   let Func = SFunc('RunReceive')
#   call call(Func, [...])
#
# Usage in heredoc (note: use double-quoted heredoc or paste literally):
#   run_nvim_test <<VIMSCRIPT
#   ${RESOLVE_SID_VIM}
#   let Func = SFunc('RunReceive')
#   ...
#   VIMSCRIPT
read -r -d '' RESOLVE_SID_VIM <<'__VIM__' || true
call fujjitive#GitVersion()
let g:autoload_sid = 0
for s in split(execute("scriptnames"), "\n")
  if s =~# 'autoload/fujjitive\.vim'
    let g:autoload_sid = str2nr(matchstr(s, '^\s*\zs\d\+'))
  endif
endfor
if g:autoload_sid == 0
  echoerr 'Could not resolve autoload SID'
  cquit 1
endif
function! SFunc(name) abort
  return '<SNR>' . g:autoload_sid . '_' . a:name
endfunction
__VIM__
