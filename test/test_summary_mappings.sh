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

# ── Test: s:StageDiff on ancestor line returns diff -r <revision> ──────────

setup_jj_repo

# Create a parent commit so there's an ancestor in the log
(
  cd "$TEST_REPO"
  echo "parent content" >> file.txt
  jj commit -m "parent: add content" 2>/dev/null
)

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}

edit file.txt
J

" Find an ancestor line in the Ancestors section
if !search('^Ancestors', 'w')
  echoerr 'Could not find Ancestors section'
  cquit 1
endif
" Move to the first log line after the heading
normal! j

let StageDiff = SFunc('StageDiff')
let result = call(StageDiff, ['Gdiffsplit'])

" Verify result contains 'diff -r' and looks like a revision diff command
if result !~# 'diff -r'
  echoerr 'Expected "diff -r" in StageDiff result, got: ' . result
  cquit 1
endif
if result !~# 'JJ --paginate diff -r'
  echoerr 'Expected "JJ --paginate diff -r" in result, got: ' . result
  cquit 1
endif
VIMSCRIPT
then pass "s:StageDiff on ancestor line returns diff -r <revision>"
else fail "s:StageDiff on ancestor line returns diff -r <revision>"
fi

cleanup

# ── Test: s:StageDiff on section heading returns plain diff ────────────────

setup_jj_repo

# Create an ancestor so the Ancestors section exists
(
  cd "$TEST_REPO"
  jj commit -m "parent commit" 2>/dev/null
)

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}

edit file.txt
J

" Find the Ancestors section heading
if !search('^Ancestors (', 'w')
  echoerr 'Could not find Ancestors section'
  cquit 1
endif

let StageDiff = SFunc('StageDiff')
let result = call(StageDiff, ['Gdiffsplit'])

" Verify result is the plain fallback (no -r flag)
if result !=# 'JJ --paginate diff'
  echoerr 'Expected plain "JJ --paginate diff" on section heading, got: ' . result
  cquit 1
endif
VIMSCRIPT
then pass "s:StageDiff on section heading returns plain diff"
else fail "s:StageDiff on section heading returns plain diff"
fi

cleanup

# ── Test: s:StageDiffEdit on ancestor line returns diff -r <revision> ──────

setup_jj_repo

# Create a parent commit
(
  cd "$TEST_REPO"
  echo "parent content" >> file.txt
  jj commit -m "parent: add content" 2>/dev/null
)

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}

edit file.txt
J

" Find an ancestor line
if !search('^Ancestors', 'w')
  echoerr 'Could not find Ancestors section'
  cquit 1
endif
normal! j

let StageDiffEdit = SFunc('StageDiffEdit')
let result = call(StageDiffEdit, [])

" Verify result contains 'diff -r'
if result !~# 'JJ --paginate diff -r'
  echoerr 'Expected "JJ --paginate diff -r" in StageDiffEdit result, got: ' . result
  cquit 1
endif
VIMSCRIPT
then pass "s:StageDiffEdit on ancestor line returns diff -r <revision>"
else fail "s:StageDiffEdit on ancestor line returns diff -r <revision>"
fi

cleanup

# ── Test: s:StageDiffEdit on section heading returns plain diff ────────────

setup_jj_repo

# Create an ancestor
(
  cd "$TEST_REPO"
  jj commit -m "parent commit" 2>/dev/null
)

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}

edit file.txt
J

" Find the Ancestors section heading
if !search('^Ancestors (', 'w')
  echoerr 'Could not find Ancestors section'
  cquit 1
endif

let StageDiffEdit = SFunc('StageDiffEdit')
let result = call(StageDiffEdit, [])

" Verify result is the plain fallback with tree path (no -r flag)
if result =~# 'diff -r'
  echoerr 'Expected no "-r" flag on section heading, got: ' . result
  cquit 1
endif
if result !~# 'JJ --paginate diff'
  echoerr 'Expected "JJ --paginate diff" on section heading, got: ' . result
  cquit 1
endif
VIMSCRIPT
then pass "s:StageDiffEdit on section heading returns plain diff"
else fail "s:StageDiffEdit on section heading returns plain diff"
fi

cleanup

finish
