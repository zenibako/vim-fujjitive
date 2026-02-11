#!/usr/bin/env bash
# test/test_config.sh — Tests for fujjitive#Config() and related functions.
#
# Validates:
#   - fujjitive#Config() returns a dict-like object
#   - fujjitive#ConfigGetAll() retrieves config values
#   - fujjitive#ExpireConfig() clears the cache

source "$(dirname "$0")/helpers.sh"

_bold "Config tests"

# ── Prereq ──────────────────────────────────────────────────────────────────

if ! command -v jj &>/dev/null; then
  _bold "  SKIP: jj not found — skipping all config tests"
  finish
fi

# ── Test: fujjitive#Config() returns a dict ──────────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
let config = fujjitive#Config()
if type(config) != type({})
  echoerr 'Config() should return a dict, got type: ' . type(config)
  cquit 1
endif
VIMSCRIPT
then pass "fujjitive#Config() returns a dict"
else fail "fujjitive#Config() returns a dict"
fi

cleanup

# ── Test: fujjitive#ConfigGetAll with user.name ──────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
let values = fujjitive#ConfigGetAll('user.name')
if type(values) != type([])
  echoerr 'ConfigGetAll should return a list, got type: ' . type(values)
  cquit 1
endif
" user.name should be set (we set JJ_USER in the environment)
if empty(values)
  echoerr 'ConfigGetAll("user.name") returned empty list'
  cquit 1
endif
VIMSCRIPT
then pass "fujjitive#ConfigGetAll('user.name') returns non-empty list"
else fail "fujjitive#ConfigGetAll('user.name') returns non-empty list"
fi

cleanup

# ── Test: fujjitive#ExpireConfig clears cache ────────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt

" Load config first
let config1 = fujjitive#Config()
if type(config1) != type({})
  echoerr 'First Config() call failed'
  cquit 1
endif

" Expire the cache
call fujjitive#ExpireConfig(0)

" Load again — should still work (returns fresh config)
let config2 = fujjitive#Config()
if type(config2) != type({})
  echoerr 'Config() after ExpireConfig failed'
  cquit 1
endif
VIMSCRIPT
then pass "fujjitive#ExpireConfig(0) clears and re-fetches config"
else fail "fujjitive#ExpireConfig(0) clears and re-fetches config"
fi

cleanup

finish
