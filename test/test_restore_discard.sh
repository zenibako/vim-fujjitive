#!/usr/bin/env bash
# test/test_restore_discard.sh — Tests for restore/discard workflow (U, X keymaps).
#
# Validates:
#   - U restores all working copy changes (jj diff empty after)
#   - X on a tracked file in Changes section restores it from parent (@-)
#   - X on an untracked file deletes it from the filesystem
#   - X on a commit line populates typeahead with :JJ abandon <change_id>
#   - X on a section heading populates typeahead with :JJ abandon "<revset>"
#   - Visual-mode X on multiple commit lines includes all change IDs

source "$(dirname "$0")/helpers.sh"

_bold "Restore/discard (U, X) tests"

# ── Prereq ──────────────────────────────────────────────────────────────────

if ! command -v jj &>/dev/null; then
  _bold "  SKIP: jj not found — skipping all restore/discard tests"
  finish
fi

# Helper: drain feedkeys typeahead into a variable.
read -r -d '' DRAIN_TYPEAHEAD_VIM <<'__VIM__' || true
function! DrainTypeahead() abort
  let keys = ''
  while 1
    let c = getchar(0)
    if c == 0
      break
    endif
    let keys .= nr2char(c)
  endwhile
  return keys
endfunction
__VIM__

# ── Test: U mapping is wired to :JJ restore ────────────────────────────────
#
# U is mapped to :<C-U>JJ restore<CR> which goes through the :JJ Run
# pipeline.  Verify the mapping is correct.

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let mapping = maparg('U', 'n')
if mapping !~# 'JJ restore'
  echoerr 'U mapping does not contain "JJ restore", got: ' . mapping
  cquit 1
endif
VIMSCRIPT
then pass "U is mapped to :JJ restore"
else fail "U is mapped to :JJ restore"
fi

cleanup

# ── Test: U restores all working copy changes ──────────────────────────────
#
# Verify that after executing the U keymap, jj diff is empty.
# We test this by calling jj restore directly (same as what :JJ restore does)
# since the :JJ Run pipeline editor protocol doesn't work headlessly.

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "work" 2>/dev/null
  echo "modified" >> file.txt
  echo "modified" >> other.txt
)

# Verify changes exist before restore
pre_diff="$(jj diff --stat -R "$TEST_REPO" 2>/dev/null)"
if [[ -z "$pre_diff" ]]; then
  fail "U restores all working copy changes" "precondition: no changes to restore"
else
  if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}

edit file.txt
J

" Call TreeChomp('restore') directly — same as what the handler does
let TreeChomp = SFunc('TreeChomp')
call call(TreeChomp, ['restore'])
VIMSCRIPT
  then
    wc_diff="$(jj diff --stat -R "$TEST_REPO" 2>/dev/null)"
    if [[ -z "$wc_diff" ]] || [[ "$wc_diff" == "0 files changed, 0 insertions(+), 0 deletions(-)" ]]; then
      pass "U restores all working copy changes"
    else
      fail "U restores all working copy changes" "diff still has changes: $wc_diff"
    fi
  else
    fail "U restores all working copy changes" "nvim exited non-zero"
  fi
fi

cleanup

# ── Test: X on a tracked file restores it from parent ──────────────────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "work" 2>/dev/null
  echo "modified" >> file.txt
  echo "modified" >> other.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

" Move cursor to the file.txt line in Changes section
if !search('^M file\.txt')
  echoerr 'file.txt not found in status buffer. Buffer: ' . join(getline(1, '$'), "\n")
  cquit 1
endif

" Execute X keymap on the file line
execute "normal X"
sleep 500m
qall!
VIMSCRIPT
then
  # file.txt should be restored; other.txt should still be changed
  wc_diff="$(jj diff --stat -R "$TEST_REPO" 2>/dev/null)"
  if [[ "$wc_diff" == *"other.txt"* ]] && [[ "$wc_diff" != *"file.txt"* ]]; then
    pass "X on tracked file restores it from parent"
  elif [[ "$wc_diff" == *"file.txt"* ]]; then
    fail "X on tracked file restores it from parent" "file.txt still changed: $wc_diff"
  else
    fail "X on tracked file restores it from parent" "unexpected state: $wc_diff"
  fi
else
  fail "X on tracked file restores it from parent" "nvim exited non-zero"
fi

cleanup

# ── Test: X on an untracked file deletes it from the filesystem ────────────

setup_jj_repo

(
  cd "$TEST_REPO"
  jj new -m "untracked test" 2>/dev/null
  echo "new content" > newfile.txt
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

" Move cursor to the untracked file line
if !search('^? newfile\.txt')
  " Try alternate status format
  if !search('^A newfile\.txt')
    echoerr 'newfile.txt not found. Buffer: ' . join(getline(1, '$'), "\n")
    cquit 1
  endif
endif

execute "normal X"
sleep 500m
qall!
VIMSCRIPT
then
  if [[ ! -f "$TEST_REPO/newfile.txt" ]]; then
    pass "X on untracked file deletes it from filesystem"
  else
    fail "X on untracked file deletes it from filesystem" "newfile.txt still exists"
  fi
else
  fail "X on untracked file deletes it from filesystem" "nvim exited non-zero"
fi

cleanup

# ── Test: X on a commit line populates typeahead with :JJ abandon ──────────
#
# The "Other mutable" section heading starts with "Other", which is a key in
# abandon_revsets.  Individual commit lines in that section go through the
# Selection() path.

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

" Inject an Other mutable section with commit lines
setlocal modifiable noreadonly
call append(line('\$'), ['', 'Other mutable (2)', 'xkqrst feat: side work', 'mnopqr fix: cleanup'])
setlocal nomodifiable readonly

" Move cursor to the first commit line
call search('^xkqrst ')
let StageDelete = SFunc('StageDelete')
call call(StageDelete, [line('.'), 0, 0])

let keys = DrainTypeahead()
if keys !~# ':JJ abandon xkqrst'
  echoerr 'Expected ":JJ abandon xkqrst", got: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "X on commit line in Other mutable produces :JJ abandon <change_id>"
else fail "X on commit line in Other mutable produces :JJ abandon <change_id>"
fi

cleanup

# ── Test: X on Other mutable heading produces :JJ abandon with revset ──────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

" Inject an Other mutable section
setlocal modifiable noreadonly
call append(line('\$'), ['', 'Other mutable (1)', 'xkqrst feat: side work'])
setlocal nomodifiable readonly

" Move cursor to the section heading
call search('^Other mutable ')
let StageDelete = SFunc('StageDelete')
call call(StageDelete, [line('.'), 0, 0])

let keys = DrainTypeahead()
if keys !~# ':JJ abandon "mutable() \~ ::@"'
  echoerr 'Expected :JJ abandon "mutable() ~ ::@", got: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "X on Other mutable heading produces :JJ abandon with revset"
else fail "X on Other mutable heading produces :JJ abandon with revset"
fi

cleanup

# ── Test: Visual-mode X on multiple commit lines includes all change IDs ───

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

" Inject an Other mutable section with multiple commits
setlocal modifiable noreadonly
call append(line('\$'), ['', 'Other mutable (3)', 'xkqrst feat: side work', 'mnopqr fix: cleanup', 'pqrstu chore: refactor'])
setlocal nomodifiable readonly

" Find line numbers for first and last commit
call search('^xkqrst ')
let first = line('.')
call search('^pqrstu ')
let last = line('.')

" Call StageDelete with visual range (lnum1, lnum2)
let StageDelete = SFunc('StageDelete')
call call(StageDelete, [first, last, 0])

let keys = DrainTypeahead()
" All three change IDs should be in the abandon command
if keys !~# ':JJ abandon'
  echoerr 'Expected :JJ abandon, got: ' . keys
  cquit 1
endif
if keys !~# 'xkqrst'
  echoerr 'Missing xkqrst in abandon command: ' . keys
  cquit 1
endif
if keys !~# 'mnopqr'
  echoerr 'Missing mnopqr in abandon command: ' . keys
  cquit 1
endif
if keys !~# 'pqrstu'
  echoerr 'Missing pqrstu in abandon command: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "Visual-mode X on multiple commits includes all change IDs"
else fail "Visual-mode X on multiple commits includes all change IDs"
fi

cleanup

# ── Test: X on Ancestors commit line does NOT produce abandon ──────────────
#
# The Ancestors section is NOT in abandon_revsets, so X on a commit in
# Ancestors should NOT produce an abandon command.

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

" Inject an Ancestors section with a commit
setlocal modifiable noreadonly
call append(line('\$'), ['', 'Ancestors (1)', 'xkqrst feat: ancestor work'])
setlocal nomodifiable readonly

call search('^xkqrst ')
let StageDelete = SFunc('StageDelete')
call call(StageDelete, [line('.'), 0, 0])

let keys = DrainTypeahead()
" Ancestors are not in abandon_revsets, so no :JJ abandon should appear
if keys =~# ':JJ abandon'
  echoerr 'X on Ancestors commit should not produce abandon, got: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "X on Ancestors commit does not produce :JJ abandon"
else fail "X on Ancestors commit does not produce :JJ abandon"
fi

cleanup

finish
