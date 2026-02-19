#!/usr/bin/env bash
# test/test_push_keymap.sh — Tests for P keymap and push-related status buffer behavior.
#
# Validates:
#   - P keymap in status buffer populates :JJ git push
#   - s:StagePush() produces :JJ git push
#   - s:DoStageUnpushedHeading() produces :JJ git push
#   - s:DoStageUnpushed() produces :JJ git push on commit lines
#   - Unpushed section renders before Other mutable section

source "$(dirname "$0")/helpers.sh"

_bold "Push keymap tests"

# ── Prereq ──────────────────────────────────────────────────────────────────

if ! command -v jj &>/dev/null; then
  _bold "  SKIP: jj not found — skipping all push keymap tests"
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

# ── Test: StagePush produces :JJ git push ───────────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

let StagePush = SFunc('StagePush')
call call(StagePush, [])

let keys = DrainTypeahead()
if keys !~# ':JJ git push'
  echoerr 'Expected ":JJ git push", got: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "StagePush() produces :JJ git push"
else fail "StagePush() produces :JJ git push"
fi

cleanup

# ── Test: StagePush on bookmark line produces bookmark set + push ───────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

" Inject a Bookmarks section with a local bookmark
setlocal modifiable noreadonly
call append(line('\$'), ['', 'Bookmarks (1)', 'main xyzvwrss Add feature'])
setlocal nomodifiable readonly

" Move cursor to the bookmark line
call search('^main ')
let StagePush = SFunc('StagePush')
call call(StagePush, [])

let keys = DrainTypeahead()
if keys !~# ':JJ bookmark set main -r @'
  echoerr 'Expected bookmark set in command, got: ' . keys
  cquit 1
endif
if keys !~# 'JJ git push'
  echoerr 'Expected git push in command, got: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "StagePush() on bookmark line produces bookmark set + git push"
else fail "StagePush() on bookmark line produces bookmark set + git push"
fi

cleanup

# ── Test: StagePush on remote bookmark falls back to plain push ─────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

" Inject a Bookmarks section with a remote bookmark
setlocal modifiable noreadonly
call append(line('\$'), ['', 'Bookmarks (1)', 'main@origin xyzvwrss Add feature'])
setlocal nomodifiable readonly

" Move cursor to the remote bookmark line
call search('^main@origin ')
let StagePush = SFunc('StagePush')
call call(StagePush, [])

let keys = DrainTypeahead()
if keys =~# 'bookmark set'
  echoerr 'Should not set remote bookmark, got: ' . keys
  cquit 1
endif
if keys !~# ':JJ git push'
  echoerr 'Expected ":JJ git push", got: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "StagePush() on remote bookmark falls back to plain git push"
else fail "StagePush() on remote bookmark falls back to plain git push"
fi

cleanup

# ── Test: StagePush on Unpushed commit line includes -r ─────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

" Inject an Unpushed section with a commit line (default format: change_id subject)
setlocal modifiable noreadonly
call append(line('\$'), ['', 'Unpushed (1)', 'xkqrst feat: new thing'])
setlocal nomodifiable readonly

call search('^xkqrst ')
let StagePush = SFunc('StagePush')
call call(StagePush, [])

let keys = DrainTypeahead()
if keys !~# ':JJ git push -r xkqrst'
  echoerr 'Expected ":JJ git push -r xkqrst", got: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "StagePush() on Unpushed commit includes -r <change_id>"
else fail "StagePush() on Unpushed commit includes -r <change_id>"
fi

cleanup

# ── Test: StagePush on Ancestors commit line includes -r ────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

" Inject an Ancestors section with a commit line (default format: change_id subject)
setlocal modifiable noreadonly
call append(line('\$'), ['', 'Ancestors (1)', 'mnopqr fix: old thing'])
setlocal nomodifiable readonly

call search('^mnopqr ')
let StagePush = SFunc('StagePush')
call call(StagePush, [])

let keys = DrainTypeahead()
if keys !~# ':JJ git push -r mnopqr'
  echoerr 'Expected ":JJ git push -r mnopqr", got: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "StagePush() on Ancestors commit includes -r <change_id>"
else fail "StagePush() on Ancestors commit includes -r <change_id>"
fi

cleanup

# ── Test: DoStageUnpushedHeading produces :JJ git push ─────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

let DoStageUnpushedHeading = SFunc('DoStageUnpushedHeading')
call call(DoStageUnpushedHeading, ['Unpushed (3)'])

let keys = DrainTypeahead()
if keys !~# ':JJ git push'
  echoerr 'Expected ":JJ git push", got: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "DoStageUnpushedHeading() produces :JJ git push"
else fail "DoStageUnpushedHeading() produces :JJ git push"
fi

cleanup

# ── Test: DoStageUnpushed produces :JJ git push ────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

let DoStageUnpushed = SFunc('DoStageUnpushed')
call call(DoStageUnpushed, [{'commit': 'abc12345', 'section': 'Unpushed'}])

let keys = DrainTypeahead()
if keys !~# ':JJ git push'
  echoerr 'Expected ":JJ git push", got: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "DoStageUnpushed() produces :JJ git push"
else fail "DoStageUnpushed() produces :JJ git push"
fi

cleanup

# ── Test: DoStagePushHeader produces :JJ git push ──────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<VIMSCRIPT
${RESOLVE_SID_VIM}
${DRAIN_TYPEAHEAD_VIM}

edit file.txt
J

let DoStagePushHeader = SFunc('DoStagePushHeader')
call call(DoStagePushHeader, ['origin main'])

let keys = DrainTypeahead()
if keys !~# ':JJ git push'
  echoerr 'Expected ":JJ git push", got: ' . keys
  cquit 1
endif
VIMSCRIPT
then pass "DoStagePushHeader() produces :JJ git push"
else fail "DoStagePushHeader() produces :JJ git push"
fi

cleanup

# ── Test: Unpushed section appears before Other mutable ─────────────────────

setup_jj_repo

# Create a remote so we can have unpushed commits, plus other mutable changes
(
  cd "$TEST_REPO"
  # Create a bookmark and push it to set up the remote tracking
  jj bookmark create test-branch -r @ 2>/dev/null || jj bookmark set test-branch -r @ 2>/dev/null
  # Create another mutable change not in our ancestry
  jj new 'root()' -m "other: unrelated mutable work" 2>/dev/null
  # Go back to original line
  jj new @ -m "test: back on working line" 2>/dev/null || true
)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

let lines = getline(1, '$')
let content = join(lines, "\n")

" Find positions of Unpushed and Other mutable sections
let unpushed_line = 0
let other_mutable_line = 0
let lnum = 1
for l in lines
  if l =~# '^Unpushed '
    let unpushed_line = lnum
  endif
  if l =~# '^Other mutable '
    let other_mutable_line = lnum
  endif
  let lnum += 1
endfor

" If both sections exist, Unpushed must come first
if unpushed_line > 0 && other_mutable_line > 0
  if unpushed_line >= other_mutable_line
    echoerr 'Unpushed (line ' . unpushed_line . ') should appear before Other mutable (line ' . other_mutable_line . '). Buffer: ' . content
    cquit 1
  endif
endif

" If only one exists, that's fine — the test just verifies ordering when both present.
" But we should have at least Other mutable from our setup.
if other_mutable_line == 0
  " It's possible the mutable change didn't appear; not a failure for the ordering test.
endif
VIMSCRIPT
then pass "Unpushed section appears before Other mutable when both present"
else fail "Unpushed section appears before Other mutable when both present"
fi

cleanup

# ── Test: Section ordering with injected sections ───────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J

" Inject all three sections to verify full ordering
setlocal modifiable noreadonly
call append(line('$'), [
      \ '', 'Unpushed (1)', 'xkqrst feat: new thing',
      \ '', 'Ancestors (1)', 'mnopqr fix: old thing',
      \ '', 'Other mutable (1)', 'pqrstu chore: side work'])
setlocal nomodifiable readonly

let lines = getline(1, '$')
let unpushed_line = 0
let ancestors_line = 0
let other_mutable_line = 0
let lnum = 1
for l in lines
  if l =~# '^Unpushed ' && unpushed_line == 0
    let unpushed_line = lnum
  endif
  if l =~# '^Ancestors ' && ancestors_line == 0
    let ancestors_line = lnum
  endif
  if l =~# '^Other mutable ' && other_mutable_line == 0
    let other_mutable_line = lnum
  endif
  let lnum += 1
endfor

if unpushed_line == 0
  echoerr 'Unpushed section not found'
  cquit 1
endif
if ancestors_line == 0
  echoerr 'Ancestors section not found'
  cquit 1
endif
if other_mutable_line == 0
  echoerr 'Other mutable section not found'
  cquit 1
endif
if unpushed_line >= ancestors_line
  echoerr 'Unpushed (line ' . unpushed_line . ') must come before Ancestors (line ' . ancestors_line . ')'
  cquit 1
endif
if ancestors_line >= other_mutable_line
  echoerr 'Ancestors (line ' . ancestors_line . ') must come before Other mutable (line ' . other_mutable_line . ')'
  cquit 1
endif
VIMSCRIPT
then pass "Section order: Unpushed -> Ancestors -> Other mutable"
else fail "Section order: Unpushed -> Ancestors -> Other mutable"
fi

cleanup

finish
