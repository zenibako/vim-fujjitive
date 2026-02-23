#!/usr/bin/env bash
# test/test_syntax_highlight.sh — Tests for syntax highlighting rules.
#
# Validates:
#   - Commit descriptions are not highlighted as symbolic refs in log sections
#   - Change IDs, hashes, workspace names, and markers are highlighted correctly
#   - Header lines still highlight symbolic refs (bookmark names)

source "$(dirname "$0")/helpers.sh"

_bold "Syntax highlighting tests"

# ── Helper: syngroup at line,col ─────────────────────────────────────────────

# All tests source a common preamble that loads the syntax file and populates
# the buffer with representative status-buffer content.
read -r -d '' SYNTAX_PREAMBLE <<'__VIM__' || true
set ft=fujjitive
syntax on
runtime syntax/fujjitive.vim

call setline(1, [
  \ "Working copy: yz default@ (empty) (no description set)",
  \ "Parent: syvptqku 2b8aaf07 master | fix: scope Unpushed section",
  \ "Help: g?",
  \ "",
  \ "Ancestors (4)",
  \ "vzq fix: use Vim command separator",
  \ "suvtz [ODA-27442] Bug / Fix getSiteName functions",
  \ "pmv default@ (empty) (no description set)",
  \ "k feat: add P keymap for push",
  \ "",
  \ "Bookmarks (1)",
  \ "master s fix: scope Unpushed section"])
redraw

function! SynAt(line, col) abort
  return synIDattr(synID(a:line, a:col, 1), 'name')
endfunction
__VIM__

# ── Test: description words not highlighted as SymbolicRef in log section ────

if run_nvim_test <<VIMSCRIPT
${SYNTAX_PREAMBLE}

" Line 6: vzq fix: use Vim command separator
" 'fix' must NOT be fujjitiveSymbolicRef
let syn = SynAt(6, 5)
if syn ==# 'fujjitiveSymbolicRef'
  echoerr 'Description word "fix" on line 6 col 5 falsely highlighted as fujjitiveSymbolicRef'
  cquit 1
endif

" Line 7: suvtz [ODA-27442] Bug / Fix getSiteName
" '[ODA-27442]' must NOT be fujjitiveSymbolicRef
let syn = SynAt(7, 7)
if syn ==# 'fujjitiveSymbolicRef'
  echoerr 'Bracketed ticket "[ODA-27442]" on line 7 col 7 falsely highlighted as fujjitiveSymbolicRef'
  cquit 1
endif

" Line 9: k feat: add P keymap for push
" 'feat' must NOT be fujjitiveSymbolicRef
let syn = SynAt(9, 3)
if syn ==# 'fujjitiveSymbolicRef'
  echoerr 'Description word "feat" on line 9 col 3 falsely highlighted as fujjitiveSymbolicRef'
  cquit 1
endif
VIMSCRIPT
then pass "Commit descriptions not highlighted as symbolic refs in log sections"
else fail "Commit descriptions not highlighted as symbolic refs in log sections"
fi

# ── Test: change IDs highlighted in log section ──────────────────────────────

if run_nvim_test <<VIMSCRIPT
${SYNTAX_PREAMBLE}

" Line 6: vzq — should be fujjitiveChangeId
let syn = SynAt(6, 1)
if syn !=# 'fujjitiveChangeId'
  echoerr 'Change ID "vzq" on line 6 col 1 not highlighted as fujjitiveChangeId, got: ' . syn
  cquit 1
endif

" Line 9: k — single-letter change ID
let syn = SynAt(9, 1)
if syn !=# 'fujjitiveChangeId'
  echoerr 'Change ID "k" on line 9 col 1 not highlighted as fujjitiveChangeId, got: ' . syn
  cquit 1
endif
VIMSCRIPT
then pass "Change IDs highlighted correctly in log sections"
else fail "Change IDs highlighted correctly in log sections"
fi

# ── Test: workspace names and markers highlighted in log section ─────────────

if run_nvim_test <<VIMSCRIPT
${SYNTAX_PREAMBLE}

" Line 8: pmv default@ (empty) (no description set)
" 'default@' should be fujjitiveWorkspaceName
let syn = SynAt(8, 5)
if syn !=# 'fujjitiveWorkspaceName'
  echoerr 'Workspace name "default@" on line 8 col 5 not highlighted as fujjitiveWorkspaceName, got: ' . syn
  cquit 1
endif

" '(empty)' should be fujjitiveEmpty
let syn = SynAt(8, 14)
if syn !=# 'fujjitiveEmpty'
  echoerr '(empty) marker on line 8 col 14 not highlighted as fujjitiveEmpty, got: ' . syn
  cquit 1
endif
VIMSCRIPT
then pass "Workspace names and (empty) markers highlighted in log sections"
else fail "Workspace names and (empty) markers highlighted in log sections"
fi

# ── Test: header lines still highlight symbolic refs ─────────────────────────

if run_nvim_test <<VIMSCRIPT
${SYNTAX_PREAMBLE}

" Line 1: Working copy: yz default@ (empty) (no description set)
" 'yz' should be fujjitiveHeaderChangeId
let syn = SynAt(1, 16)
if syn !=# 'fujjitiveHeaderChangeId'
  echoerr 'Change ID "yz" on header line 1 col 16 not highlighted as fujjitiveHeaderChangeId, got: ' . syn
  cquit 1
endif

" Line 2: Parent: syvptqku 2b8aaf07 master | fix: scope Unpushed section
" 'master' should be fujjitiveSymbolicRef
let syn = SynAt(2, 28)
if syn !=# 'fujjitiveSymbolicRef'
  echoerr 'Bookmark "master" on header line 2 col 28 not highlighted as fujjitiveSymbolicRef, got: ' . syn
  cquit 1
endif

" '2b8aaf07' should be fujjitiveHeaderHash
let syn = SynAt(2, 19)
if syn !=# 'fujjitiveHeaderHash'
  echoerr 'Hash "2b8aaf07" on header line 2 col 19 not highlighted as fujjitiveHeaderHash, got: ' . syn
  cquit 1
endif
VIMSCRIPT
then pass "Header lines highlight symbolic refs and IDs correctly"
else fail "Header lines highlight symbolic refs and IDs correctly"
fi

# ── Test: bookmark names highlighted in Bookmarks section ────────────────────

if run_nvim_test <<VIMSCRIPT
${SYNTAX_PREAMBLE}

" Line 12: master s fix: scope Unpushed section
" 'master' should be fujjitiveBookmarkName
let syn = SynAt(12, 1)
if syn !=# 'fujjitiveBookmarkName'
  echoerr 'Bookmark name "master" on line 12 col 1 not highlighted as fujjitiveBookmarkName, got: ' . syn
  cquit 1
endif
VIMSCRIPT
then pass "Bookmark names highlighted in Bookmarks section"
else fail "Bookmark names highlighted in Bookmarks section"
fi

# ── Test: description after header pipe delimiter not highlighted ─────────────

if run_nvim_test <<VIMSCRIPT
${SYNTAX_PREAMBLE}

" Line 2: Parent: syvptqku 2b8aaf07 master | fix: scope Unpushed section
" 'fix' after the pipe should NOT be fujjitiveSymbolicRef
let syn = SynAt(2, 37)
if syn ==# 'fujjitiveSymbolicRef'
  echoerr 'Description word "fix" after pipe on header line 2 col 37 falsely highlighted as fujjitiveSymbolicRef'
  cquit 1
endif
VIMSCRIPT
then pass "Description after pipe delimiter on header not highlighted as symbolic ref"
else fail "Description after pipe delimiter on header not highlighted as symbolic ref"
fi

finish
