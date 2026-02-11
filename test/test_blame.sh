#!/usr/bin/env bash
# test/test_blame.sh — Tests for :J blame / :G blame (jj file annotate).
#
# Validates:
#   - :J blame opens a scrollbound split with fujjitiveblame filetype
#   - Blame output matches expected git-blame-compatible format
#   - Each blame line has balanced parentheses in the annotation
#   - :G blame also works (routed through git_to_jj_commands)

source "$(dirname "$0")/helpers.sh"

_bold "Blame tests"

# ── Prereq ──────────────────────────────────────────────────────────────────

if ! command -v jj &>/dev/null; then
  _bold "  SKIP: jj not found — skipping all blame tests"
  finish
fi

# ── Test: :J blame opens a fujjitiveblame buffer ────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J blame

" The blame split should have fujjitiveblame filetype
if &filetype !=# 'fujjitiveblame'
  echoerr 'Expected filetype=fujjitiveblame, got: ' . &filetype
  cquit 1
endif

" Buffer should have content (at least one line of blame)
if line('$') <= 0 || getline(1) ==# ''
  echoerr 'Blame buffer is empty'
  cquit 1
endif
VIMSCRIPT
then pass ":J blame opens buffer with filetype=fujjitiveblame"
else fail ":J blame opens buffer with filetype=fujjitiveblame"
fi

cleanup

# ── Test: blame output has git-blame-compatible format ──────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J blame

" Each line should match: <hex> <num> (<author> <date> <num>) <content>
let line = getline(1)

" Check hex hash at start (12 hex characters)
let hash = matchstr(line, '^\x\{12\}')
if empty(hash)
  echoerr 'Line does not start with 12-char hex hash: ' . line
  cquit 1
endif

" Check the full format: hash, line number, (author date linenum) content
" The annotation should contain the closing ) preceded by digits
if line !~# '^\x\{12\}\s\+\d\+\s\+(.\+\s\+\d\+)'
  echoerr 'Line does not match expected blame format: ' . line
  cquit 1
endif
VIMSCRIPT
then pass "Blame output matches git-blame-compatible format"
else fail "Blame output matches git-blame-compatible format"
fi

cleanup

# ── Test: every blame line has balanced annotation parens ───────────────────

setup_jj_repo

# Add multiple lines so there's more to validate
printf 'line one\nline two\nline three\n' > "$TEST_REPO/file.txt"
(cd "$TEST_REPO" && jj describe -m "test: add multiple lines" 2>/dev/null)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J blame

" Check every non-empty line in the blame buffer
let errors = []
for lnum in range(1, line('$'))
  let line = getline(lnum)
  if empty(line)
    continue
  endif

  " Each line must have ( before ) in the annotation
  let open = stridx(line, '(')
  " Find the ) that is preceded by digits (the annotation close)
  let close = match(line, '\d)')
  if open < 0
    call add(errors, 'Line ' . lnum . ' missing open paren: ' . line)
  elseif close < 0
    call add(errors, 'Line ' . lnum . ' missing close paren after digits: ' . line)
  elseif close < open
    call add(errors, 'Line ' . lnum . ' close paren before open paren: ' . line)
  endif
endfor

if !empty(errors)
  echoerr join(errors, "\n")
  cquit 1
endif
VIMSCRIPT
then pass "All blame lines have balanced annotation parentheses"
else fail "All blame lines have balanced annotation parentheses"
fi

cleanup

# ── Test: :G blame works as an alias ────────────────────────────────────────

setup_jj_repo

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
G blame

" Should produce the same fujjitiveblame filetype
if &filetype !=# 'fujjitiveblame'
  echoerr 'Expected filetype=fujjitiveblame from :G blame, got: ' . &filetype
  cquit 1
endif

" Verify the output has the expected format
let line = getline(1)
if line !~# '^\x\{12\}\s\+\d\+\s\+(.\+\s\+\d\+)'
  echoerr ':G blame output format unexpected: ' . line
  cquit 1
endif
VIMSCRIPT
then pass ":G blame works and produces correct output format"
else fail ":G blame works and produces correct output format"
fi

cleanup

# ── Test: blame with revision argument ──────────────────────────────────────

setup_jj_repo

# Create a second commit so we can blame a specific revision
(cd "$TEST_REPO" && jj new 2>/dev/null && echo "updated" > file.txt && jj describe -m "test: second change" 2>/dev/null)

if run_nvim_test_in "$TEST_REPO" <<'VIMSCRIPT'
edit file.txt
J blame @-

" Should still get a valid blame buffer
if &filetype !=# 'fujjitiveblame'
  echoerr 'Expected filetype=fujjitiveblame for revision blame, got: ' . &filetype
  cquit 1
endif

let line = getline(1)
if line !~# '^\x\{12\}\s\+\d\+\s\+(.\+\s\+\d\+)'
  echoerr 'Revision blame output format unexpected: ' . line
  cquit 1
endif
VIMSCRIPT
then pass ":J blame with revision argument produces correct output"
else fail ":J blame with revision argument produces correct output"
fi

cleanup

finish
