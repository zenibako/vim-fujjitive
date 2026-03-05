#!/usr/bin/env bash
# test/test_split_squash.sh — Tests for split/squash workflow (s, u, -, ce keymaps).
#
# Validates:
#   - s on a file line in Changes section runs jj split -- <file>
#   - s on Changes section heading dispatches to DoSplitUnstagedHeading
#   - u on a file line runs jj squash -- <file>
#   - u on Changes section heading dispatches to DoSquashUnstagedHeading
#   - - (toggle) on Changes file behaves same as split
#   - ce is mapped to :JJ squash
#   - Section name normalization (Changes -> Unstaged) works for Do* dispatch

source "$(dirname "$0")/helpers.sh"

_bold "Split/squash workflow tests"

# ── Prereq ──────────────────────────────────────────────────────────────────

if ! command -v jj &>/dev/null; then
  _bold "  SKIP: jj not found — skipping all split/squash tests"
  finish
fi

# jj split and squash open an editor for the description.
# Use 'true' (exits 0, no-op) so commands succeed headlessly.
export JJ_EDITOR=true

# ── Test: s on a file line splits that file into a new change ───────────────

setup_jj_repo

# Set up: parent has initial content, working copy modifies two files
(
  cd "$TEST_REPO"
  jj new -m "work on two files" 2>/dev/null
  echo "extra line" >> file.txt
  echo "extra line" >> other.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

" Verify Changes section exists with our files
let lines = getline(1, '$')
let has_changes = 0
for l in lines
  if l =~# '^Changes '
    let has_changes = 1
    break
  endif
endfor
if !has_changes
  echoerr 'Missing Changes section. Buffer: ' . join(lines, "\n")
  cquit 1
endif

" Move cursor to the file.txt line
if !search('^M file\.txt')
  echoerr 'file.txt not found in status buffer. Buffer: ' . join(getline(1, '$'), "\n")
  cquit 1
endif

" Execute s (split) keymap — this calls s:Do('Split', 0)
execute "normal s"

" Give jj time to complete
sleep 1
qall!
VIMSCRIPT
then
  # Verify that file.txt was split into a new child change.
  # After split, the working copy should still have other.txt changes
  # but file.txt should have moved to a parent change.
  wc_diff="$(jj diff --stat -R "$TEST_REPO" 2>/dev/null)"
  if [[ "$wc_diff" == *"other.txt"* ]] && [[ "$wc_diff" != *"file.txt"* ]]; then
    pass "s on file line splits file.txt out of working copy"
  elif [[ "$wc_diff" == *"file.txt"* ]]; then
    fail "s on file line splits file.txt out of working copy" "file.txt still in working copy diff: $wc_diff"
  else
    fail "s on file line splits file.txt out of working copy" "unexpected diff state: $wc_diff"
  fi
else
  fail "s on file line splits file.txt out of working copy" "nvim exited non-zero"
fi

cleanup

# ── Test: s on Changes heading dispatches to DoSplitUnstagedHeading ─────────
#
# Bare `jj split` (no fileset args) requires an interactive terminal for the
# diff editor, so we cannot run it end-to-end in headless mode.  Instead, we
# verify the dispatch: calling s:Do('Split', 0) on the Changes heading finds
# and calls s:DoSplitUnstagedHeading thanks to section normalization.

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "work on all files" 2>/dev/null
  echo "extra" >> file.txt
  echo "extra" >> other.txt
)

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}

edit file.txt
J

" Verify the heading exists
if !search('^Changes ')
  echoerr 'Changes heading not found. Buffer: ' . join(getline(1, '\$'), "\n")
  cquit 1
endif

" Check that section normalization resolves the handler
let NormalizeSection = SFunc('NormalizeSection')
let section = call(NormalizeSection, ['Changes'])
if section !=# 'Unstaged'
  echoerr 'NormalizeSection("Changes") returned "' . section . '", expected "Unstaged"'
  cquit 1
endif

" Verify the handler function exists for the normalized section
if !exists('*' . SFunc('DoSplitUnstagedHeading'))
  echoerr 'DoSplitUnstagedHeading function not found'
  cquit 1
endif
VIMSCRIPT
then pass "s on Changes heading dispatches to DoSplitUnstagedHeading"
else fail "s on Changes heading dispatches to DoSplitUnstagedHeading"
fi

cleanup

# ── Test: u on a file line squashes that file into parent ───────────────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "work on two files" 2>/dev/null
  echo "extra line" >> file.txt
  echo "extra line" >> other.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

" Move cursor to the file.txt line
if !search('^M file\.txt')
  echoerr 'file.txt not found. Buffer: ' . join(getline(1, '$'), "\n")
  cquit 1
endif

" Execute u (squash) keymap
execute "normal u"
sleep 1
qall!
VIMSCRIPT
then
  # After squash, file.txt change should be absorbed into parent.
  # Working copy should only have other.txt changes.
  wc_diff="$(jj diff --stat -R "$TEST_REPO" 2>/dev/null)"
  if [[ "$wc_diff" == *"other.txt"* ]] && [[ "$wc_diff" != *"file.txt"* ]]; then
    pass "u on file line squashes file.txt into parent"
  elif [[ "$wc_diff" == *"file.txt"* ]]; then
    fail "u on file line squashes file.txt into parent" "file.txt still in working copy: $wc_diff"
  else
    fail "u on file line squashes file.txt into parent" "unexpected diff state: $wc_diff"
  fi
else
  fail "u on file line squashes file.txt into parent" "nvim exited non-zero"
fi

cleanup

# ── Test: u on Changes heading squashes all files ───────────────────────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "work on all files" 2>/dev/null
  echo "extra" >> file.txt
  echo "extra" >> other.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

if !search('^Changes ')
  echoerr 'Changes heading not found. Buffer: ' . join(getline(1, '$'), "\n")
  cquit 1
endif

execute "normal u"
sleep 1
qall!
VIMSCRIPT
then
  wc_diff="$(jj diff --stat -R "$TEST_REPO" 2>/dev/null)"
  if [[ -z "$wc_diff" ]] || [[ "$wc_diff" == "0 files changed, 0 insertions(+), 0 deletions(-)" ]]; then
    pass "u on Changes heading squashes all files into parent"
  else
    fail "u on Changes heading squashes all files into parent" "working copy still has changes: $wc_diff"
  fi
else
  fail "u on Changes heading squashes all files into parent" "nvim exited non-zero"
fi

cleanup

# ── Test: - (toggle) on file line behaves same as split ─────────────────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "toggle test" 2>/dev/null
  echo "extra line" >> file.txt
  echo "extra line" >> other.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

if !search('^M file\.txt')
  echoerr 'file.txt not found. Buffer: ' . join(getline(1, '$'), "\n")
  cquit 1
endif

" Execute - (toggle) keymap
execute "normal -"
sleep 1
qall!
VIMSCRIPT
then
  wc_diff="$(jj diff --stat -R "$TEST_REPO" 2>/dev/null)"
  if [[ "$wc_diff" == *"other.txt"* ]] && [[ "$wc_diff" != *"file.txt"* ]]; then
    pass "- (toggle) on file line splits file.txt out of working copy"
  elif [[ "$wc_diff" == *"file.txt"* ]]; then
    fail "- (toggle) on file line splits file.txt out of working copy" "file.txt still in working copy: $wc_diff"
  else
    fail "- (toggle) on file line splits file.txt out of working copy" "unexpected diff state: $wc_diff"
  fi
else
  fail "- (toggle) on file line splits file.txt out of working copy" "nvim exited non-zero"
fi

cleanup

# ── Test: ce maps to :JJ squash ─────────────────────────────────────────────
#
# ce is mapped to :<C-U>JJ squash<CR> which goes through the :JJ Run pipeline.
# The Run pipeline sets its own JJ_EDITOR (fujjitive editor protocol), which
# does not work in headless mode.  Test that the mapping exists and is correct.

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

" Verify ce mapping exists and maps to JJ squash
let mapping = maparg('ce', 'n')
if mapping !~# 'JJ squash'
  echoerr 'ce mapping does not contain "JJ squash", got: ' . mapping
  cquit 1
endif
VIMSCRIPT
then pass "ce is mapped to :JJ squash"
else fail "ce is mapped to :JJ squash"
fi

cleanup

# ── Test: Section normalization maps Changes to Unstaged ────────────────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "normalization test" 2>/dev/null
  echo "change" >> file.txt
)

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}

edit file.txt
J

" Move to a file line in Changes section
if !search('^M file\.txt')
  echoerr 'file.txt not found. Buffer: ' . join(getline(1, '\$'), "\n")
  cquit 1
endif

" Use Selection() to get the section for the file
let Selection = SFunc('Selection')
let result = call(Selection, [line('.'), 0])

if empty(result)
  echoerr 'Selection() returned empty for file line'
  cquit 1
endif

let section = get(result[0], 'section', '')
if section !=# 'Unstaged'
  echoerr 'Expected section "Unstaged" but got "' . section . '"'
  cquit 1
endif

" Verify Do* handler exists for this section
if !exists('*' . SFunc('DoSplitUnstaged'))
  echoerr 'DoSplitUnstaged function not found'
  cquit 1
endif
if !exists('*' . SFunc('DoSquashUnstaged'))
  echoerr 'DoSquashUnstaged function not found'
  cquit 1
endif
if !exists('*' . SFunc('DoToggleUnstaged'))
  echoerr 'DoToggleUnstaged function not found'
  cquit 1
endif
VIMSCRIPT
then pass "Selection() normalizes Changes section to Unstaged for Do* dispatch"
else fail "Selection() normalizes Changes section to Unstaged for Do* dispatch"
fi

cleanup

finish
