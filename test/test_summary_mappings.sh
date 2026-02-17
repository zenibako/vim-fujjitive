#!/usr/bin/env bash
# test/test_summary_mappings.sh — Tests for cs/cS/cn mappings in the summary buffer.
#
# Validates:
#   - cs mapping runs :JJ squash (squash into parent)
#   - cS mapping runs :JJ squash (same as cs)
#   - cn mapping runs :JJ new (create new change)
#   - cs integration: squashing actually moves changes into parent
#   - cn integration: a new empty change is created

source "$(dirname "$0")/helpers.sh"

_bold "Summary buffer mapping tests (cs/cS/cn)"

# ── Prereq ──────────────────────────────────────────────────────────────────

if ! command -v jj &>/dev/null; then
  _bold "  SKIP: jj not found — skipping all summary mapping tests"
  finish
fi

# ── Test: cs mapping is defined and points to :JJ squash ────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let mapping = maparg('cs', 'n')
if mapping !~# 'JJ squash'
  echoerr 'cs mapping should contain "JJ squash", got: ' . mapping
  cquit 1
endif
VIMSCRIPT
then pass "cs mapping points to :JJ squash"
else fail "cs mapping points to :JJ squash"
fi

cleanup

# ── Test: cS mapping is defined and points to :JJ squash ────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let mapping = maparg('cS', 'n')
if mapping !~# 'JJ squash'
  echoerr 'cS mapping should contain "JJ squash", got: ' . mapping
  cquit 1
endif
VIMSCRIPT
then pass "cS mapping points to :JJ squash"
else fail "cS mapping points to :JJ squash"
fi

cleanup

# ── Test: cn mapping is defined and points to :JJ new ───────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let mapping = maparg('cn', 'n')
if mapping !~# 'JJ new'
  echoerr 'cn mapping should contain "JJ new", got: ' . mapping
  cquit 1
endif
VIMSCRIPT
then pass "cn mapping points to :JJ new"
else fail "cn mapping points to :JJ new"
fi

cleanup

# ── Test: cs integration — squash moves changes into parent ─────────────────

setup_jj_repo

# Create a parent commit, then modify a file in the new working copy
(
  cd "$TEST_REPO"
  jj commit -m "parent commit" 2>/dev/null
  echo "new content" >> file.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J
execute "normal cs"
sleep 2
VIMSCRIPT
then
  # After squash, working copy should have no file changes
  wc_diff="$(jj diff -R "$TEST_REPO" 2>/dev/null)"
  if [[ -z "$wc_diff" ]]; then
    pass "cs squashes working copy changes into parent"
  else
    fail "cs squashes working copy changes into parent" "working copy still has changes: $wc_diff"
  fi
else
  fail "cs squashes working copy changes into parent" "nvim exited non-zero"
fi

cleanup

# ── Test: cn integration — new change is created ────────────────────────────

setup_jj_repo

pre_change="$(jj log -r @ --no-graph -T 'change_id' -R "$TEST_REPO" 2>/dev/null)"

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J
execute "normal cn"
sleep 2
VIMSCRIPT
then
  post_change="$(jj log -r @ --no-graph -T 'change_id' -R "$TEST_REPO" 2>/dev/null)"
  if [[ "$post_change" != "$pre_change" ]]; then
    pass "cn creates a new change (change_id differs)"
  else
    fail "cn creates a new change" "change_id did not change: $pre_change"
  fi
else
  fail "cn creates a new change" "nvim exited non-zero"
fi

cleanup

finish
