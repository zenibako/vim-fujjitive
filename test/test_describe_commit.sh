#!/usr/bin/env bash
# test/test_describe_commit.sh — Tests for non-interactive :JJ describe and :JJ commit.
#
# Validates:
#   - :JJ describe -m "msg" changes the working copy description
#   - :JJ commit -m "msg" creates a new change

source "$(dirname "$0")/helpers.sh"

_bold "Describe and commit tests"

# ── Prereq ──────────────────────────────────────────────────────────────────

if ! command -v jj &>/dev/null; then
  _bold "  SKIP: jj not found — skipping all describe/commit tests"
  finish
fi

# ── Test: :JJ describe -m changes working copy description ──────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
JJ describe -m "test description from nvim"
sleep 2
VIMSCRIPT
then
  # Verify the description was actually set via jj CLI
  desc="$(jj log -r @ --no-graph -T 'description' -R "$TEST_REPO" 2>/dev/null)"
  if [[ "$desc" == *"test description from nvim"* ]]; then
    pass ":JJ describe -m sets working copy description"
  else
    fail ":JJ describe -m sets working copy description" "got description: $desc"
  fi
else
  fail ":JJ describe -m sets working copy description" "nvim exited non-zero"
fi

cleanup

# ── Test: :JJ commit -m creates a new change ────────────────────────────────

setup_jj_repo

# Get the current change id before commit
pre_change="$(jj log -r @ --no-graph -T 'change_id' -R "$TEST_REPO" 2>/dev/null)"

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
JJ commit -m "committed from nvim"
sleep 2
VIMSCRIPT
then
  # After commit, @ should be a new change (different from pre_change)
  post_change="$(jj log -r @ --no-graph -T 'change_id' -R "$TEST_REPO" 2>/dev/null)"
  if [[ "$post_change" != "$pre_change" ]]; then
    # Verify the parent has the commit message
    parent_desc="$(jj log -r '@-' --no-graph -T 'description' -R "$TEST_REPO" 2>/dev/null)"
    if [[ "$parent_desc" == *"committed from nvim"* ]]; then
      pass ":JJ commit -m creates new change with message on parent"
    else
      fail ":JJ commit -m creates new change with message on parent" "parent desc: $parent_desc"
    fi
  else
    fail ":JJ commit -m creates new change" "change_id did not change: $pre_change"
  fi
else
  fail ":JJ commit -m creates new change" "nvim exited non-zero"
fi

cleanup

finish
