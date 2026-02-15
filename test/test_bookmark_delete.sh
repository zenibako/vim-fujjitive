#!/usr/bin/env bash
# test/test_bookmark_delete.sh — Tests for X keymap on bookmark lines.
#
# Validates:
#   - s:Selection() parses local bookmark lines in the Bookmarks section
#   - s:Selection() parses remote bookmark lines (name@remote) in the Bookmarks section
#   - s:StageDelete() produces correct command for local bookmark deletion
#   - s:StageDelete() produces correct command for remote bookmark untracking
#   - s:StageDelete() is a no-op on the Bookmarks heading itself
#   - Visual mode X on multiple local bookmarks batches them

source "$(dirname "$0")/helpers.sh"

_bold "Bookmark delete (X) tests"

# ── Prereq ──────────────────────────────────────────────────────────────────

if ! command -v jj &>/dev/null; then
  _bold "  SKIP: jj not found — skipping all bookmark delete tests"
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

# ── Test: Selection parses local bookmark line ──────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}

edit file.txt
J

" Inject a fake Bookmarks section into the buffer
setlocal modifiable noreadonly
call append(line('\$'), ['', 'Bookmarks (2)', 'main xyzvwrss Add new feature', 'dev tqklnmpp Fix parser bug'])
setlocal nomodifiable readonly

" Move cursor to the first bookmark line ("main ...")
call search('^main ')
let Selection = SFunc('Selection')
let result = call(Selection, [line('.'), 0])

if empty(result)
  echoerr 'Selection returned empty for local bookmark line'
  cquit 1
endif
if get(result[0], 'section', '') !=# 'Bookmarks'
  echoerr 'section is not Bookmarks, got: ' . get(result[0], 'section', '(empty)')
  cquit 1
endif
if get(result[0], 'lnum', 0) != line('.')
  echoerr 'lnum mismatch: expected ' . line('.') . ', got ' . get(result[0], 'lnum', 0)
  cquit 1
endif
VIMSCRIPT
then pass "Selection() parses local bookmark line in Bookmarks section"
else fail "Selection() parses local bookmark line in Bookmarks section"
fi

cleanup

# ── Test: Selection parses remote bookmark line ─────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}

edit file.txt
J

setlocal modifiable noreadonly
call append(line('\$'), ['', 'Bookmarks (2)', 'main xyzvwrss Add feature', 'main@origin tqklnmpp Fix bug'])
setlocal nomodifiable readonly

" Move cursor to the remote bookmark line
call search('^main@origin ')
let Selection = SFunc('Selection')
let result = call(Selection, [line('.'), 0])

if empty(result)
  echoerr 'Selection returned empty for remote bookmark line'
  cquit 1
endif
if get(result[0], 'section', '') !=# 'Bookmarks'
  echoerr 'section is not Bookmarks, got: ' . get(result[0], 'section', '(empty)')
  cquit 1
endif
VIMSCRIPT
then pass "Selection() parses remote bookmark line (name@remote)"
else fail "Selection() parses remote bookmark line (name@remote)"
fi

cleanup

# ── Test: Selection parses hyphenated bookmark name ─────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}

edit file.txt
J

setlocal modifiable noreadonly
call append(line('\$'), ['', 'Bookmarks (1)', 'my-feature xyzvwrss Some work'])
setlocal nomodifiable readonly

call search('^my-feature ')
let Selection = SFunc('Selection')
let result = call(Selection, [line('.'), 0])

if empty(result)
  echoerr 'Selection returned empty for hyphenated bookmark name'
  cquit 1
endif
if get(result[0], 'section', '') !=# 'Bookmarks'
  echoerr 'section is not Bookmarks, got: ' . get(result[0], 'section', '(empty)')
  cquit 1
endif
VIMSCRIPT
then pass "Selection() parses hyphenated bookmark name"
else fail "Selection() parses hyphenated bookmark name"
fi

cleanup

# ── Test: StageDelete produces bookmark delete for local bookmark ───────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

setlocal modifiable noreadonly
call append(line('\$'), ['', 'Bookmarks (1)', 'my-feature xyzvwrss Some work'])
setlocal nomodifiable readonly

call search('^my-feature ')
let StageDelete = SFunc('StageDelete')
let result = call(StageDelete, [line('.'), 0, 0])

let keys = DrainTypeahead()
if keys !~# ':JJ bookmark delete my-feature'
  echoerr 'Expected ":JJ bookmark delete my-feature", got: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "StageDelete() produces :JJ bookmark delete for local bookmark"
else fail "StageDelete() produces :JJ bookmark delete for local bookmark"
fi

cleanup

# ── Test: StageDelete produces bookmark untrack for remote bookmark ─────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

setlocal modifiable noreadonly
call append(line('\$'), ['', 'Bookmarks (1)', 'main@origin tqklnmpp Fix bug'])
setlocal nomodifiable readonly

call search('^main@origin ')
let StageDelete = SFunc('StageDelete')
let result = call(StageDelete, [line('.'), 0, 0])

let keys = DrainTypeahead()
if keys !~# ':JJ bookmark untrack main --remote origin'
  echoerr 'Expected ":JJ bookmark untrack main --remote origin", got: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "StageDelete() produces :JJ bookmark untrack for remote bookmark"
else fail "StageDelete() produces :JJ bookmark untrack for remote bookmark"
fi

cleanup

# ── Test: StageDelete is no-op on Bookmarks heading ────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

setlocal modifiable noreadonly
call append(line('\$'), ['', 'Bookmarks (2)', 'main xyzvwrss Feature', 'dev tqklnmpp Fix'])
setlocal nomodifiable readonly

" Move to the heading line
call search('^Bookmarks (')
let StageDelete = SFunc('StageDelete')
let result = call(StageDelete, [line('.'), 0, 0])

let keys = DrainTypeahead()
if keys =~# 'bookmark'
  echoerr 'X on Bookmarks heading should be no-op, but got: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "StageDelete() is no-op on Bookmarks section heading"
else fail "StageDelete() is no-op on Bookmarks section heading"
fi

cleanup

# ── Test: StageDelete batches multiple local bookmarks ──────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

setlocal modifiable noreadonly
call append(line('\$'), ['', 'Bookmarks (3)', 'main xyzvwrss Feature', 'dev tqklnmpp Fix', 'release wkrtlyxx Release'])
setlocal nomodifiable readonly

" Find the line numbers for the first and last bookmark
call search('^main ')
let first = line('.')
call search('^release ')
let last = line('.')

let StageDelete = SFunc('StageDelete')
let result = call(StageDelete, [first, last, 0])

let keys = DrainTypeahead()
if keys !~# ':JJ bookmark delete main dev release'
  echoerr 'Expected ":JJ bookmark delete main dev release", got: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "StageDelete() batches multiple local bookmarks into one delete"
else fail "StageDelete() batches multiple local bookmarks into one delete"
fi

cleanup

# ── Test: Real bookmark appears in status buffer and X works ────────────────

setup_jj_repo

# Create a real bookmark in the test repo
(
  cd "$TEST_REPO"
  jj bookmark create test-bookmark -r @ 2>/dev/null || jj bookmark set test-bookmark -r @ 2>/dev/null
)

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

let lines = getline(1, '\$')
let content = join(lines, "\n")

" Verify the Bookmarks section exists
let has_bookmarks = 0
for l in lines
  if l =~# '^Bookmarks '
    let has_bookmarks = 1
    break
  endif
endfor
if !has_bookmarks
  echoerr 'Missing Bookmarks section. Buffer: ' . content
  cquit 1
endif

" Verify our bookmark appears
let has_test_bm = 0
for l in lines
  if l =~# '^test-bookmark '
    let has_test_bm = 1
    break
  endif
endfor
if !has_test_bm
  echoerr 'test-bookmark not found in buffer. Buffer: ' . content
  cquit 1
endif

" Now test X on it
call search('^test-bookmark ')
let StageDelete = SFunc('StageDelete')
let result = call(StageDelete, [line('.'), 0, 0])

let keys = DrainTypeahead()
if keys !~# ':JJ bookmark delete test-bookmark'
  echoerr 'Expected :JJ bookmark delete test-bookmark, got: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "X on real bookmark in status buffer produces correct delete command"
else fail "X on real bookmark in status buffer produces correct delete command"
fi

cleanup

finish
